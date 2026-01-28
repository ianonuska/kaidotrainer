extends Node
class_name DetectionClient
"""
Client for communicating with the Python detection server.

Usage:
    var client = DetectionClient.new()
    add_child(client)

    # Connect to server
    client.connect_to_server()

    # Start detection pipeline
    client.start_pipeline()

    # Run detection
    client.detect()

    # Connect to signals for results
    client.detection_complete.connect(_on_detection_complete)
    client.comparison_complete.connect(_on_comparison_complete)
"""

# Signals
signal connected()
signal disconnected()
signal connection_failed(error: String)
signal detection_complete(result: DetectionResult)
signal comparison_complete(result: ComparisonResult)
signal error(message: String)

# Server connection
var host: String = "localhost"
var port: int = 9876
var _socket: StreamPeerTCP
var _connected: bool = false
var _buffer: String = ""

# Pending requests
var _pending_callback: Callable

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_socket = StreamPeerTCP.new()

func _process(_delta: float) -> void:
	# Check if we're still trying to connect
	if _connecting:
		_check_connection()
		return

	if not _connected:
		return

	# Check connection status
	var status = _socket.get_status()
	if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
		_handle_disconnect()
		return

	# Read available data
	var available = _socket.get_available_bytes()
	if available > 0:
		var data = _socket.get_string(available)
		_buffer += data
		_process_buffer()

func _process_buffer() -> void:
	# Process complete JSON messages (newline-delimited)
	while "\n" in _buffer:
		var idx = _buffer.find("\n")
		var line = _buffer.substr(0, idx)
		_buffer = _buffer.substr(idx + 1)

		if line.strip_edges().length() > 0:
			_handle_response(line)

# ============================================================================
# CONNECTION
# ============================================================================

func connect_to_server(server_host: String = "localhost", server_port: int = 9876) -> void:
	"""Connect to the detection server."""
	host = server_host
	port = server_port
	print("[DetectionClient] Connecting to ", host, ":", port)

	var err = _socket.connect_to_host(host, port)
	if err != OK:
		print("[DetectionClient] Failed to initiate: ", err)
		connection_failed.emit("Failed to initiate connection: " + str(err))
		return

	# Start polling for connection in _process instead of blocking
	_connecting = true
	_connect_attempts = 0

var _connecting: bool = false
var _connect_attempts: int = 0
const MAX_CONNECT_ATTEMPTS: int = 50  # 5 seconds at 10 checks/sec

func _check_connection() -> void:
	"""Check connection status (called from _process)."""
	if not _connecting:
		return

	_socket.poll()
	var status = _socket.get_status()

	# Debug: print status every 10 attempts
	if _connect_attempts % 10 == 0:
		print("[DetectionClient] Status: ", status, " (attempt ", _connect_attempts, ")")

	if status == StreamPeerTCP.STATUS_CONNECTED:
		_connecting = false
		_connected = true
		print("[DetectionClient] Connected!")
		connected.emit()
	elif status == StreamPeerTCP.STATUS_ERROR:
		_connecting = false
		print("[DetectionClient] Connection error (status=", status, ")")
		connection_failed.emit("Connection error")
	elif status == StreamPeerTCP.STATUS_NONE:
		# Socket was reset or never started - this is an error
		_connecting = false
		print("[DetectionClient] Connection failed - socket reset")
		connection_failed.emit("Connection reset")
	else:
		# STATUS_CONNECTING - keep waiting
		_connect_attempts += 1
		if _connect_attempts >= MAX_CONNECT_ATTEMPTS:
			_connecting = false
			print("[DetectionClient] Connection timeout after ", _connect_attempts, " attempts")
			connection_failed.emit("Connection timeout")

func disconnect_from_server() -> void:
	"""Disconnect from the server."""
	if _connected:
		_send_command({"command": "quit"})
		_socket.disconnect_from_host()
		_handle_disconnect()

func _handle_disconnect() -> void:
	_connected = false
	disconnected.emit()

func is_connected_to_server() -> bool:
	return _connected

# ============================================================================
# COMMANDS
# ============================================================================

func ping() -> void:
	"""Test connection with ping."""
	_send_command({"command": "ping"})

func start_pipeline() -> void:
	"""Start the detection pipeline on the server."""
	_send_command({"command": "start"})

func stop_pipeline() -> void:
	"""Stop the detection pipeline."""
	_send_command({"command": "stop"})

func detect() -> void:
	"""
	Run a single detection cycle.

	Results emitted via detection_complete signal.
	"""
	_send_command({"command": "detect"})

func compare(expected_circuit: Dictionary) -> void:
	"""
	Detect and compare to expected circuit.

	Args:
		expected_circuit: Dictionary with circuit definition
		{
			"name": "LED Circuit",
			"components": [
				{"type": "led", "label": "LED1"},
				{"type": "resistor", "value": "330ohm", "label": "R1"}
			],
			"topology": "series"
		}

	Results emitted via comparison_complete signal.
	"""
	_send_command({
		"command": "compare",
		"expected": expected_circuit
	})

func get_status() -> void:
	"""Get server/pipeline status."""
	_send_command({"command": "status"})

func configure(use_mock: bool = false, model_path: String = "") -> void:
	"""Configure the detection pipeline."""
	var cmd = {"command": "configure", "use_mock": use_mock}
	if model_path.length() > 0:
		cmd["model_path"] = model_path
	_send_command(cmd)

# ============================================================================
# COMMUNICATION
# ============================================================================

func _send_command(command: Dictionary) -> void:
	"""Send a command to the server."""
	if not _connected:
		error.emit("Not connected to server")
		return

	var json_str = JSON.stringify(command) + "\n"
	_socket.put_data(json_str.to_utf8_buffer())

func _handle_response(json_str: String) -> void:
	"""Handle a JSON response from the server."""
	var json = JSON.new()
	var parse_result = json.parse(json_str)

	if parse_result != OK:
		error.emit("Failed to parse server response: " + json_str)
		return

	var response = json.data

	if response.get("status") == "error":
		error.emit(response.get("message", "Unknown error"))
		return

	var data = response.get("data", {})

	# Route response based on content
	if data.has("circuit_state") and data.has("comparison"):
		# Compare result
		var result = ComparisonResult.from_dict(data)
		comparison_complete.emit(result)
	elif data.has("circuit_state"):
		# Detection result
		var result = DetectionResult.from_dict(data)
		detection_complete.emit(result)
	# Other responses (status, configure, etc.) - could add more signals

# ============================================================================
# DATA CLASSES
# ============================================================================

class DetectionResult:
	var circuit_state: CircuitState
	var timing: Dictionary
	var quality: String

	static func from_dict(data: Dictionary) -> DetectionResult:
		var result = DetectionResult.new()
		result.circuit_state = CircuitState.from_dict(data.get("circuit_state", {}))
		result.timing = data.get("timing", {})
		result.quality = data.get("quality", "unknown")
		return result

class ComparisonResult:
	var circuit_state: CircuitState
	var is_correct: bool
	var score: float
	var errors: Array[CircuitError]
	var hint: String
	var matched_count: int
	var missing_count: int
	var extra_count: int

	static func from_dict(data: Dictionary) -> ComparisonResult:
		var result = ComparisonResult.new()
		result.circuit_state = CircuitState.from_dict(data.get("circuit_state", {}))
		result.is_correct = data.get("is_correct", false)
		result.score = data.get("score", 0.0)
		result.hint = data.get("hint", "")

		var comparison = data.get("comparison", {})
		result.matched_count = comparison.get("matched_count", 0)
		result.missing_count = comparison.get("missing_count", 0)
		result.extra_count = comparison.get("extra_count", 0)

		result.errors = []
		for err_data in comparison.get("errors", []):
			var err = CircuitError.from_dict(err_data)
			result.errors.append(err)

		return result

class CircuitState:
	var components: Array[DetectedComponent]
	var confidence: float

	static func from_dict(data: Dictionary) -> CircuitState:
		var state = CircuitState.new()
		state.confidence = data.get("confidence", 0.0)
		state.components = []

		for comp_data in data.get("components", []):
			var comp = DetectedComponent.from_dict(comp_data)
			state.components.append(comp)

		return state

	func get_component_count() -> int:
		return components.size()

	func has_component_type(type_name: String) -> bool:
		for comp in components:
			if comp.type == type_name:
				return true
		return false

class DetectedComponent:
	var type: String
	var leg1_row: int
	var leg1_col: String
	var leg2_row: int
	var leg2_col: String
	var confidence: float
	var value: String
	var color: String

	static func from_dict(data: Dictionary) -> DetectedComponent:
		var comp = DetectedComponent.new()
		comp.type = data.get("type", "unknown")
		comp.confidence = data.get("confidence", 0.0)
		comp.value = data.get("value", "")
		comp.color = data.get("color", "")

		var leg1 = data.get("leg1", {})
		comp.leg1_row = leg1.get("row", 0)
		comp.leg1_col = leg1.get("col", "a")

		var leg2 = data.get("leg2")
		if leg2:
			comp.leg2_row = leg2.get("row", 0)
			comp.leg2_col = leg2.get("col", "a")

		return comp

	func get_position_string() -> String:
		var pos1 = leg1_col.to_upper() + str(leg1_row)
		if leg2_col:
			var pos2 = leg2_col.to_upper() + str(leg2_row)
			return pos1 + " - " + pos2
		return pos1

class CircuitError:
	var code: String
	var severity: String
	var message: String
	var component_type: String

	static func from_dict(data: Dictionary) -> CircuitError:
		var err = CircuitError.new()
		err.code = data.get("code", "UNKNOWN")
		err.severity = data.get("severity", "info")
		err.message = data.get("message", "")
		err.component_type = data.get("component_type", "")
		return err

	func is_critical() -> bool:
		return severity == "critical"

	func is_warning() -> bool:
		return severity == "warning"
