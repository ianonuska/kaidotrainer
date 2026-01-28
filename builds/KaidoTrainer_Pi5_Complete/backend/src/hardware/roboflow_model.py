"""
Roboflow Model Integration for KaidoTrainer.

This module provides a drop-in replacement for TFLite detection using
Roboflow's local inference (on-device) or cloud API as fallback.

LOCAL INFERENCE (preferred):
    - Uses `inference` package from Roboflow
    - Model downloads once, then runs locally forever
    - Works offline after first download
    - Fast (~200-500ms on Pi)

CLOUD API (fallback):
    - Uses HTTP API to Roboflow cloud
    - Requires internet connection
    - Slower (~2-3 seconds)

Usage:
    # Via config file (recommended)
    model = RoboflowDetectionModel.from_config("config/model_config.json")

    # Direct instantiation
    model = RoboflowDetectionModel(
        api_key="your_api_key",
        project="circuit-detection-uz75t",
        version=3,
    )

    model.load()
    output = model.detect(image)
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from pathlib import Path
import time
import json
import base64
import io

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False
    np = None

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    requests = None

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    Image = None

# Roboflow local inference (preferred)
try:
    from inference import get_model as rf_get_model
    HAS_INFERENCE = True
except ImportError:
    HAS_INFERENCE = False
    rf_get_model = None

# Define our own data classes to avoid TFLite/TensorFlow dependency
from dataclasses import dataclass, field
from typing import List, Tuple

@dataclass
class Detection:
    """A single detection result."""
    class_id: int
    class_name: str
    confidence: float
    bbox: Tuple[float, float, float, float]  # (x1, y1, x2, y2)

@dataclass
class ModelOutput:
    """Output from model inference."""
    detections: List[Detection] = field(default_factory=list)
    inference_time_ms: float = 0
    image_width: int = 0
    image_height: int = 0

@dataclass
class ModelConfig:
    """Model configuration."""
    confidence_threshold: float = 0.5
    nms_threshold: float = 0.3


# =============================================================================
# CONFIGURATION
# =============================================================================

@dataclass
class RoboflowConfig:
    """Configuration for Roboflow model."""
    # API settings
    api_key: str = ""
    project: str = "circuit-detection-uz75t"
    version: int = 3

    # Inference settings
    confidence_threshold: float = 0.5
    overlap_threshold: float = 0.3
    max_detections: int = 20

    # Inference mode
    use_local_inference: bool = True  # Use local inference package (preferred)

    # Cloud API fallback (if local inference not available)
    api_url: str = "https://detect.roboflow.com"
    use_local: bool = False  # Legacy: local inference server via HTTP
    local_url: str = "http://localhost:9001"

    # Image settings
    resize_width: int = 640  # Resize before sending to API

    # Class mapping (Roboflow class -> ComponentType)
    class_mapping: Dict[str, str] = field(default_factory=lambda: {
        "led": "led",
        "resistor": "resistor",
        "wire": "wire",
        "button": "button",
        "buzzer": "buzzer",
        "potentiometer": "potentiometer",
        "ldr": "photoresistor",
        "photoresistor": "photoresistor",
    })

    @classmethod
    def from_file(cls, path: Path) -> "RoboflowConfig":
        """Load config from JSON file."""
        with open(path) as f:
            data = json.load(f)
        return cls(**data)

    def save(self, path: Path) -> None:
        """Save config to JSON file."""
        with open(path, 'w') as f:
            json.dump({
                "api_key": self.api_key,
                "project": self.project,
                "version": self.version,
                "confidence_threshold": self.confidence_threshold,
                "overlap_threshold": self.overlap_threshold,
                "max_detections": self.max_detections,
                "use_local_inference": self.use_local_inference,
                "api_url": self.api_url,
                "use_local": self.use_local,
                "local_url": self.local_url,
                "resize_width": self.resize_width,
                "class_mapping": self.class_mapping,
            }, f, indent=2)


# =============================================================================
# ROBOFLOW DETECTION MODEL
# =============================================================================

class RoboflowDetectionModel:
    """
    Detection model using Roboflow - local inference preferred, cloud API fallback.

    Drop-in replacement for TFLite model - same interface.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        project: str = "circuit-detection-uz75t",
        version: int = 3,
        config: Optional[RoboflowConfig] = None,
    ):
        """
        Initialize Roboflow model.

        Args:
            api_key: Roboflow API key (or set in config)
            project: Roboflow project ID
            version: Model version number
            config: Full configuration (overrides other args)
        """
        if config:
            self._config = config
        else:
            self._config = RoboflowConfig(
                api_key=api_key or "",
                project=project,
                version=version,
            )

        self._is_loaded = False
        self._session = None
        self._local_model = None  # Roboflow inference model (local)
        self._use_local = False   # Whether using local inference

    @classmethod
    def from_config(cls, config_path: Path) -> "RoboflowDetectionModel":
        """Create model from config file."""
        config = RoboflowConfig.from_file(config_path)
        return cls(config=config)

    @property
    def config(self) -> RoboflowConfig:
        return self._config

    @property
    def model_id(self) -> str:
        """Return model identifier for tracking."""
        mode = "local" if self._use_local else "cloud"
        return f"roboflow-{mode}:{self._config.project}/v{self._config.version}"

    def load(self) -> bool:
        """
        Initialize the model - tries local inference first, falls back to cloud.

        Returns True if successful.
        """
        if not HAS_PIL:
            print("ERROR: Pillow library required. Install with: pip install Pillow")
            return False

        if not self._config.api_key:
            print("ERROR: Roboflow API key not set")
            return False

        # Try local inference first (preferred)
        if self._config.use_local_inference and HAS_INFERENCE:
            try:
                model_id = f"{self._config.project}/{self._config.version}"
                print(f"Loading Roboflow model locally: {model_id}")
                self._local_model = rf_get_model(model_id, api_key=self._config.api_key)
                self._use_local = True
                self._is_loaded = True
                print("  ✓ Local inference ready (on-device)")
                return True
            except Exception as e:
                print(f"  Local inference failed: {e}")
                print("  Falling back to cloud API...")

        # Fall back to cloud API
        if not HAS_REQUESTS:
            print("ERROR: requests library required for cloud API. Install with: pip install requests")
            return False

        # Create session for connection pooling
        self._session = requests.Session()
        self._use_local = False
        self._is_loaded = True
        print("  ✓ Using Roboflow cloud API")
        return True

    def unload(self) -> None:
        """Release resources."""
        self._is_loaded = False
        self._local_model = None
        self._use_local = False
        if self._session:
            self._session.close()
            self._session = None

    def detect(self, image: "np.ndarray") -> ModelOutput:
        """
        Run detection on an image.

        Args:
            image: numpy array (H, W, 3) in RGB format, uint8

        Returns:
            ModelOutput with detections
        """
        if not self._is_loaded:
            return ModelOutput(
                detections=[],
                inference_time_ms=0,
                image_width=image.shape[1] if image is not None else 0,
                image_height=image.shape[0] if image is not None else 0,
            )

        start_time = time.time()

        # Use local inference if available
        if self._use_local and self._local_model is not None:
            return self._detect_local(image, start_time)
        else:
            return self._detect_cloud(image, start_time)

    def _detect_local(self, image: "np.ndarray", start_time: float) -> ModelOutput:
        """Run detection using local inference."""
        try:
            # Run inference locally
            result = self._local_model.infer(
                image,
                confidence=self._config.confidence_threshold,
                iou_threshold=self._config.overlap_threshold,
            )

            # Handle both single result and list of results
            if isinstance(result, list):
                result = result[0] if result else None

            if result is None:
                return ModelOutput(
                    detections=[],
                    inference_time_ms=(time.time() - start_time) * 1000,
                    image_width=image.shape[1],
                    image_height=image.shape[0],
                )

            # Parse predictions from local inference result
            detections = self._parse_local_result(result, image.shape)

            inference_time = (time.time() - start_time) * 1000

            return ModelOutput(
                detections=detections,
                inference_time_ms=inference_time,
                image_width=image.shape[1],
                image_height=image.shape[0],
            )

        except Exception as e:
            print(f"Local inference error: {e}")
            return ModelOutput(
                detections=[],
                inference_time_ms=(time.time() - start_time) * 1000,
                image_width=image.shape[1] if image is not None else 0,
                image_height=image.shape[0] if image is not None else 0,
            )

    def _detect_cloud(self, image: "np.ndarray", start_time: float) -> ModelOutput:
        """Run detection using cloud API."""
        try:
            # Convert numpy array to base64 JPEG
            image_b64 = self._encode_image(image)

            # Build API URL
            if self._config.use_local:
                url = f"{self._config.local_url}/{self._config.project}/{self._config.version}"
            else:
                url = f"{self._config.api_url}/{self._config.project}/{self._config.version}"

            params = {
                "api_key": self._config.api_key,
                "confidence": int(self._config.confidence_threshold * 100),
                "overlap": int(self._config.overlap_threshold * 100),
            }

            # Send request
            response = self._session.post(
                url,
                params=params,
                data=image_b64,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=30,
            )
            response.raise_for_status()

            result = response.json()

            # Parse detections
            detections = self._parse_response(result, image.shape)

            inference_time = (time.time() - start_time) * 1000

            return ModelOutput(
                detections=detections,
                inference_time_ms=inference_time,
                image_width=image.shape[1],
                image_height=image.shape[0],
            )

        except requests.exceptions.RequestException as e:
            print(f"Roboflow API error: {e}")
            return ModelOutput(
                detections=[],
                inference_time_ms=(time.time() - start_time) * 1000,
                image_width=image.shape[1] if image is not None else 0,
                image_height=image.shape[0] if image is not None else 0,
            )
        except Exception as e:
            print(f"Detection error: {e}")
            return ModelOutput(
                detections=[],
                inference_time_ms=(time.time() - start_time) * 1000,
                image_width=image.shape[1] if image is not None else 0,
                image_height=image.shape[0] if image is not None else 0,
            )

    def _encode_image(self, image: "np.ndarray") -> str:
        """Convert numpy image to base64 JPEG string."""
        from PIL import ImageOps

        h, w = image.shape[:2]
        pil_img = Image.fromarray(image)

        # Apply EXIF orientation if present (handles rotated phone photos)
        try:
            pil_img = ImageOps.exif_transpose(pil_img)
        except Exception:
            pass  # No EXIF or unsupported

        # Resize if needed - fit within resize_width on longest side
        max_dim = max(pil_img.width, pil_img.height)
        if max_dim > self._config.resize_width:
            scale = self._config.resize_width / max_dim
            new_size = (int(pil_img.width * scale), int(pil_img.height * scale))
            pil_img = pil_img.resize(new_size, Image.LANCZOS)

        # Convert to JPEG bytes with high quality
        buffer = io.BytesIO()
        pil_img.save(buffer, format="JPEG", quality=90)
        buffer.seek(0)

        # Base64 encode
        return base64.b64encode(buffer.read()).decode('utf-8')

    def _parse_local_result(
        self,
        result: Any,
        image_shape: tuple,
    ) -> List[Detection]:
        """Parse Roboflow local inference result into Detection objects."""
        detections = []
        img_h, img_w = image_shape[:2]

        # The inference package returns an object with predictions attribute
        predictions = getattr(result, 'predictions', [])

        for pred in predictions[:self._config.max_detections]:
            # Get class name and map to our component types
            class_name = getattr(pred, 'class_name', 'unknown').lower()
            mapped_class = self._config.class_mapping.get(class_name, class_name)

            # Get bounding box - inference package uses x, y, width, height (center format)
            cx = getattr(pred, 'x', 0)
            cy = getattr(pred, 'y', 0)
            w = getattr(pred, 'width', 0)
            h = getattr(pred, 'height', 0)

            # Convert to corner format (x1, y1, x2, y2)
            x1 = cx - w / 2
            y1 = cy - h / 2
            x2 = cx + w / 2
            y2 = cy + h / 2

            detection = Detection(
                class_name=mapped_class,
                confidence=getattr(pred, 'confidence', 0.0),
                bbox=(x1, y1, x2, y2),
                class_id=getattr(pred, 'class_id', -1),
            )
            detections.append(detection)

        return detections

    def _parse_response(
        self,
        response: Dict[str, Any],
        image_shape: tuple,
    ) -> List[Detection]:
        """Parse Roboflow cloud API response into Detection objects."""
        detections = []

        predictions = response.get("predictions", [])
        img_h, img_w = image_shape[:2]

        # Scale factor if image was resized
        api_w = response.get("image", {}).get("width", img_w)
        api_h = response.get("image", {}).get("height", img_h)
        scale_x = img_w / api_w if api_w else 1.0
        scale_y = img_h / api_h if api_h else 1.0

        for pred in predictions[:self._config.max_detections]:
            # Get class name and map to our component types
            class_name = pred.get("class", "unknown").lower()
            mapped_class = self._config.class_mapping.get(class_name, class_name)

            # Get bounding box (Roboflow uses center x, center y, width, height)
            cx = pred.get("x", 0) * scale_x
            cy = pred.get("y", 0) * scale_y
            w = pred.get("width", 0) * scale_x
            h = pred.get("height", 0) * scale_y

            # Convert to corner format (x1, y1, x2, y2)
            x1 = cx - w / 2
            y1 = cy - h / 2
            x2 = cx + w / 2
            y2 = cy + h / 2

            detection = Detection(
                class_name=mapped_class,
                confidence=pred.get("confidence", 0.0),
                bbox=(x1, y1, x2, y2),
                class_id=pred.get("class_id", -1),
            )
            detections.append(detection)

        return detections


# =============================================================================
# COMPONENT CONVERSION
# =============================================================================

# Map class names to ComponentType (works with any class ID)
NAME_TO_COMPONENT = {
    "led": "LED",
    "resistor": "RESISTOR",
    "wire": "WIRE",
    "button": "BUTTON",
    "buzzer": "BUZZER",
    "potentiometer": "POTENTIOMETER",
    "ldr": "PHOTORESISTOR",
    "photoresistor": "PHOTORESISTOR",
    "capacitor": "CAPACITOR",
    "diode": "DIODE",
    "transistor": "TRANSISTOR",
}


# Grid mapper instance (initialized once, can be recalibrated)
_grid_mapper = None

def get_grid_mapper(image_width: int = 1280, image_height: int = 960) -> "GridMapper":
    """Get or create the grid mapper instance."""
    global _grid_mapper
    if _grid_mapper is None:
        from .grid_mapper import GridMapper
        _grid_mapper = GridMapper(image_width, image_height)
    return _grid_mapper

def recalibrate_grid(corners: dict) -> None:
    """
    Recalibrate the grid mapper with new corner positions.

    Args:
        corners: Dict with pixel positions of key holes:
            - 'a1': (x, y) of hole A1
            - 'e1': (x, y) of hole E1
            - 'a30': (x, y) of hole A30
            - 'f1': (x, y) of hole F1
            - 'j1': (x, y) of hole J1
    """
    mapper = get_grid_mapper()
    mapper.recalibrate(corners)


def roboflow_detections_to_components(
    output: ModelOutput,
    min_confidence: float = 0.5,
) -> list:
    """
    Convert Roboflow model output to DetectedComponent objects.

    Uses GridMapper for accurate pixel-to-breadboard position conversion.

    Args:
        output: ModelOutput from Roboflow detection
        min_confidence: Minimum confidence threshold

    Returns:
        List of DetectedComponent objects
    """
    from ..models.components import (
        ComponentType, DetectedComponent, BreadboardPosition
    )

    components = []

    # Get calibrated grid mapper
    mapper = get_grid_mapper(output.image_width, output.image_height)

    for det in output.detections:
        if det.confidence < min_confidence:
            continue

        # Map class name to ComponentType
        class_name = det.class_name.lower()
        component_name = NAME_TO_COMPONENT.get(class_name)
        if component_name is None:
            continue

        try:
            comp_type = ComponentType[component_name]
        except KeyError:
            continue

        # Get bounding box
        x1, y1, x2, y2 = det.bbox
        width = x2 - x1
        height = y2 - y1
        center_x = (x1 + x2) / 2
        center_y = (y1 + y2) / 2

        # Use GridMapper for accurate position mapping
        mapped = mapper.map_component({
            'x': center_x,
            'y': center_y,
            'width': width,
            'height': height,
            'type': class_name,
        })

        # Extract leg positions
        leg1_data = mapped.get('leg1', {})
        leg2_data = mapped.get('leg2')

        pos1 = None
        pos2 = None

        if leg1_data and leg1_data.get('valid'):
            pos1 = BreadboardPosition(
                row=leg1_data['row'],
                column=leg1_data['col']
            )

        if leg2_data and leg2_data.get('valid'):
            pos2 = BreadboardPosition(
                row=leg2_data['row'],
                column=leg2_data['col']
            )

        # Skip if we couldn't map to a valid position
        if pos1 is None:
            # Fallback to center-based estimation if mapping failed
            center_pos = mapper.pixel_to_grid(center_x, center_y)
            if center_pos.get('valid'):
                pos1 = BreadboardPosition(
                    row=center_pos['row'],
                    column=center_pos['col']
                )
            else:
                continue  # Skip component if position invalid

        components.append(DetectedComponent(
            component_type=comp_type,
            position_leg1=pos1,
            position_leg2=pos2,
            confidence=det.confidence,
            bounding_box=(x1, y1, width, height),
        ))

    return components


# =============================================================================
# IMAGE LOADING UTILITIES
# =============================================================================

def load_image_for_detection(path: Path) -> "np.ndarray":
    """
    Load an image file with proper EXIF orientation handling.

    Use this to load images for detection - handles phone photos that
    have EXIF rotation flags.

    Args:
        path: Path to image file

    Returns:
        RGB numpy array (H, W, 3)
    """
    from PIL import ImageOps

    pil_img = Image.open(path)

    # Apply EXIF orientation (handles rotated phone photos)
    pil_img = ImageOps.exif_transpose(pil_img)

    # Convert to RGB if needed
    if pil_img.mode != 'RGB':
        pil_img = pil_img.convert('RGB')

    return np.array(pil_img)


# =============================================================================
# MODEL FACTORY
# =============================================================================

def get_roboflow_model(
    config_path: Optional[Path] = None,
    api_key: Optional[str] = None,
    project: str = "circuit-detection-uz75t",
    version: int = 3,
) -> RoboflowDetectionModel:
    """
    Get a Roboflow detection model.

    Args:
        config_path: Path to config JSON (recommended)
        api_key: API key (if not using config file)
        project: Project ID
        version: Model version

    Returns:
        RoboflowDetectionModel instance
    """
    if config_path and config_path.exists():
        return RoboflowDetectionModel.from_config(config_path)

    return RoboflowDetectionModel(
        api_key=api_key,
        project=project,
        version=version,
    )


# =============================================================================
# CLI FOR TESTING
# =============================================================================

def main():
    """Command-line testing."""
    import argparse

    parser = argparse.ArgumentParser(description="Test Roboflow model")
    parser.add_argument("image", help="Path to test image")
    parser.add_argument("--config", help="Path to config JSON")
    parser.add_argument("--api-key", help="Roboflow API key")
    parser.add_argument("--project", default="circuit-detection-uz75t")
    parser.add_argument("--version", type=int, default=3)

    args = parser.parse_args()

    # Load model
    if args.config:
        model = RoboflowDetectionModel.from_config(Path(args.config))
    else:
        model = RoboflowDetectionModel(
            api_key=args.api_key,
            project=args.project,
            version=args.version,
        )

    if not model.load():
        print("Failed to load model")
        return

    # Load image
    img = np.array(Image.open(args.image))
    if img.shape[-1] == 4:  # RGBA
        img = img[:, :, :3]

    # Run detection
    output = model.detect(img)

    print(f"\nModel: {output.model_id}")
    print(f"Inference time: {output.inference_time_ms:.1f}ms")
    print(f"Detections: {len(output.detections)}")

    for det in output.detections:
        print(f"  {det.class_name}: {det.confidence:.0%} at {det.bbox}")

    model.unload()


if __name__ == "__main__":
    main()
