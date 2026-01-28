"""
Breadboard Grid Mapper
Converts pixel coordinates from CV detection to breadboard positions (e.g., "E5", "A12")

Calibration based on medium breadboard (30 rows, 10 columns a-j)
Recalibrate when switching cameras by updating the constants below.
"""

class GridMapper:
    def __init__(self, image_width=1280, image_height=960):
        """
        Initialize with calibration values.
        These values are for the iPhone test image - recalibrate for Pi Camera.
        """
        self.image_width = image_width
        self.image_height = image_height

        # ============================================================
        # CALIBRATION CONSTANTS - Adjust these for your camera setup
        # ============================================================

        # Main grid boundaries (columns a-e, left section)
        self.left_grid = {
            'x_start': 195,      # Pixel X of column 'a' center
            'x_end': 390,        # Pixel X of column 'e' center
            'y_start': 95,       # Pixel Y of row 1 center
            'y_end': 870,        # Pixel Y of row 30 center
            'columns': ['a', 'b', 'c', 'd', 'e'],
        }

        # Main grid boundaries (columns f-j, right section)
        self.right_grid = {
            'x_start': 455,      # Pixel X of column 'f' center
            'x_end': 650,        # Pixel X of column 'j' center
            'y_start': 95,       # Pixel Y of row 1 center
            'y_end': 870,        # Pixel Y of row 30 center
            'columns': ['f', 'g', 'h', 'i', 'j'],
        }

        # Power rails (left side of breadboard)
        self.left_power = {
            'positive_x': 115,   # Red + rail
            'negative_x': 145,   # Blue - rail
            'y_start': 95,
            'y_end': 870,
        }

        # Power rails (right side of breadboard)
        self.right_power = {
            'positive_x': 710,   # Red + rail
            'negative_x': 740,   # Blue - rail
            'y_start': 95,
            'y_end': 870,
        }

        # Grid dimensions
        self.num_rows = 30
        self.num_cols_per_side = 5

        # Calculate spacing
        self._calculate_spacing()

    def _calculate_spacing(self):
        """Calculate pixel spacing between holes."""
        self.row_spacing = (self.left_grid['y_end'] - self.left_grid['y_start']) / (self.num_rows - 1)
        self.col_spacing_left = (self.left_grid['x_end'] - self.left_grid['x_start']) / (self.num_cols_per_side - 1)
        self.col_spacing_right = (self.right_grid['x_end'] - self.right_grid['x_start']) / (self.num_cols_per_side - 1)

    def pixel_to_grid(self, x, y):
        """
        Convert pixel coordinates to breadboard position.

        Args:
            x: Pixel X coordinate (center of detected component)
            y: Pixel Y coordinate (center of detected component)

        Returns:
            dict with:
                - 'position': String like "E5" or "+L12" (power rail)
                - 'row': Integer row number (1-30)
                - 'col': Column letter or power rail indicator
                - 'valid': Boolean if position is on the breadboard
        """
        result = {'position': None, 'row': None, 'col': None, 'valid': False}

        # Calculate row from Y coordinate
        row = self._y_to_row(y)
        if row is None:
            return result

        result['row'] = row

        # Check which section the X coordinate falls into

        # Left power rails
        if self._in_range(x, self.left_power['positive_x'] - 20, self.left_power['positive_x'] + 20):
            result['col'] = '+L'
            result['position'] = f"+L{row}"
            result['valid'] = True
            return result

        if self._in_range(x, self.left_power['negative_x'] - 20, self.left_power['negative_x'] + 20):
            result['col'] = '-L'
            result['position'] = f"-L{row}"
            result['valid'] = True
            return result

        # Left grid (a-e)
        col = self._x_to_col_left(x)
        if col:
            result['col'] = col
            result['position'] = f"{col.upper()}{row}"
            result['valid'] = True
            return result

        # Right grid (f-j)
        col = self._x_to_col_right(x)
        if col:
            result['col'] = col
            result['position'] = f"{col.upper()}{row}"
            result['valid'] = True
            return result

        # Right power rails
        if self._in_range(x, self.right_power['positive_x'] - 20, self.right_power['positive_x'] + 20):
            result['col'] = '+R'
            result['position'] = f"+R{row}"
            result['valid'] = True
            return result

        if self._in_range(x, self.right_power['negative_x'] - 20, self.right_power['negative_x'] + 20):
            result['col'] = '-R'
            result['position'] = f"-R{row}"
            result['valid'] = True
            return result

        return result

    def _y_to_row(self, y):
        """Convert Y pixel to row number (1-30)."""
        if y < self.left_grid['y_start'] - self.row_spacing/2:
            return None
        if y > self.left_grid['y_end'] + self.row_spacing/2:
            return None

        row = round((y - self.left_grid['y_start']) / self.row_spacing) + 1
        return max(1, min(30, row))

    def _x_to_col_left(self, x):
        """Convert X pixel to column letter (a-e)."""
        if x < self.left_grid['x_start'] - self.col_spacing_left/2:
            return None
        if x > self.left_grid['x_end'] + self.col_spacing_left/2:
            return None

        col_idx = round((x - self.left_grid['x_start']) / self.col_spacing_left)
        col_idx = max(0, min(4, col_idx))
        return self.left_grid['columns'][col_idx]

    def _x_to_col_right(self, x):
        """Convert X pixel to column letter (f-j)."""
        if x < self.right_grid['x_start'] - self.col_spacing_right/2:
            return None
        if x > self.right_grid['x_end'] + self.col_spacing_right/2:
            return None

        col_idx = round((x - self.right_grid['x_start']) / self.col_spacing_right)
        col_idx = max(0, min(4, col_idx))
        return self.right_grid['columns'][col_idx]

    def _in_range(self, val, min_val, max_val):
        """Check if value is in range."""
        return min_val <= val <= max_val

    def map_component(self, detection):
        """
        Map a detected component to breadboard positions.

        Args:
            detection: Dict with 'x', 'y', 'width', 'height', 'type'
                      (x, y is center of bounding box)

        Returns:
            Dict with component type and leg positions
        """
        x = detection['x']
        y = detection['y']
        width = detection.get('width', 0)
        height = detection.get('height', 0)
        comp_type = detection.get('type', 'unknown')

        # For small components (single position)
        if width < self.col_spacing_left * 1.5 and height < self.row_spacing * 1.5:
            pos = self.pixel_to_grid(x, y)
            return {
                'type': comp_type,
                'leg1': pos,
                'leg2': None,
                'spans_gap': False
            }

        # For components that span multiple holes (LEDs, resistors, wires)
        # Estimate leg positions at top and bottom of bounding box
        if height > width:
            # Vertical component (most common)
            leg1 = self.pixel_to_grid(x, y - height/2 + 5)
            leg2 = self.pixel_to_grid(x, y + height/2 - 5)
        else:
            # Horizontal component (spanning the center gap)
            leg1 = self.pixel_to_grid(x - width/2 + 5, y)
            leg2 = self.pixel_to_grid(x + width/2 - 5, y)

        # Check if component spans the center gap
        spans_gap = False
        if leg1['valid'] and leg2['valid']:
            if leg1['col'] in ['a','b','c','d','e'] and leg2['col'] in ['f','g','h','i','j']:
                spans_gap = True
            elif leg1['col'] in ['f','g','h','i','j'] and leg2['col'] in ['a','b','c','d','e']:
                spans_gap = True

        return {
            'type': comp_type,
            'leg1': leg1,
            'leg2': leg2,
            'spans_gap': spans_gap
        }

    def are_connected(self, pos1, pos2):
        """
        Check if two positions are electrically connected on the breadboard.

        Breadboard rules:
        - Same row, columns a-e: connected
        - Same row, columns f-j: connected
        - Power rails: entire column connected
        - Center gap (e to f): NOT connected
        """
        if not pos1['valid'] or not pos2['valid']:
            return False

        col1, col2 = pos1['col'], pos2['col']
        row1, row2 = pos1['row'], pos2['row']

        # Power rail connections (entire rail is connected)
        if col1 in ['+L', '-L', '+R', '-R'] and col1 == col2:
            return True

        # Same row connections
        if row1 != row2:
            return False

        # Left side (a-e) connected
        left_cols = ['a', 'b', 'c', 'd', 'e']
        if col1 in left_cols and col2 in left_cols:
            return True

        # Right side (f-j) connected
        right_cols = ['f', 'g', 'h', 'i', 'j']
        if col1 in right_cols and col2 in right_cols:
            return True

        return False

    def recalibrate(self, corners):
        """
        Recalibrate using corner positions.

        Args:
            corners: Dict with pixel positions:
                - 'a1': (x, y) of hole A1
                - 'e1': (x, y) of hole E1
                - 'a30': (x, y) of hole A30
                - 'f1': (x, y) of hole F1
                - 'j1': (x, y) of hole J1
        """
        if 'a1' in corners and 'e1' in corners and 'a30' in corners:
            self.left_grid['x_start'] = corners['a1'][0]
            self.left_grid['x_end'] = corners['e1'][0]
            self.left_grid['y_start'] = corners['a1'][1]
            self.left_grid['y_end'] = corners['a30'][1]

        if 'f1' in corners and 'j1' in corners:
            self.right_grid['x_start'] = corners['f1'][0]
            self.right_grid['x_end'] = corners['j1'][0]
            self.right_grid['y_start'] = corners['f1'][1]
            # y_end same as left side
            self.right_grid['y_end'] = self.left_grid['y_end']

        self._calculate_spacing()
        print(f"[GridMapper] Recalibrated: row_spacing={self.row_spacing:.1f}px, col_spacing={self.col_spacing_left:.1f}px")


# Convenience function for quick testing
def test_mapper():
    """Test the grid mapper with sample coordinates."""
    mapper = GridMapper()

    # Test some positions
    test_points = [
        (195, 95, "Should be A1"),
        (390, 95, "Should be E1"),
        (455, 95, "Should be F1"),
        (650, 95, "Should be J1"),
        (300, 500, "Should be middle-left"),
        (115, 300, "Should be +L power rail"),
        (740, 300, "Should be -R power rail"),
    ]

    print("Grid Mapper Test Results:")
    print("-" * 50)
    for x, y, desc in test_points:
        result = mapper.pixel_to_grid(x, y)
        print(f"({x}, {y}): {result['position']} - {desc}")


if __name__ == "__main__":
    test_mapper()
