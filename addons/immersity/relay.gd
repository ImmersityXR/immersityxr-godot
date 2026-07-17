extends Node
## Autoload "Relay" — client for the ImmersityXR relay's /sync namespace.
##
## Wraps the Socket.IO 4.x connection made in web/immersity.js via
## JavaScriptBridge. Event names mirror services/relay/sync.js in
## immersityxr-core (see docs/PROTOCOL.md for the full contract).
##
## Outside a web export this autoload is inert: signals never fire and
## join_session()/send_update() are no-ops, so scenes remain testable in
## the editor.

signal joined(session_id: int)
signal join_failed(session_id: int, reason: String)
signal client_joined(client_id: int)
signal client_left(client_id: int)
signal client_disconnected(client_id: int)
signal state_received(state: Dictionary)
signal update_received(data: Variant)
signal message_received(data: Variant)
signal draw_received(data: Variant)
signal details_received(details: Dictionary)

var _im: JavaScriptObject
var _callbacks: Array[JavaScriptObject] = []  # prevent GC of bridge callbacks

func _ready() -> void:
	if not OS.has_feature("web"):
		push_warning("Relay: not a web export; relay networking disabled.")
		return

	_im = JavaScriptBridge.get_interface("ImmersityXR")
	_im.connectSync()

	_listen("successfullyJoined", func(a): joined.emit(int(a[0])))
	_listen("failedToJoin", func(a): join_failed.emit(int(a[0]), str(a[1])))
	_listen("joined", func(a): client_joined.emit(int(a[0])))
	_listen("left", func(a): client_left.emit(int(a[0])))
	_listen("disconnected", func(a): client_disconnected.emit(int(a[0])))
	_listen("state", func(a): state_received.emit(a[0]))
	_listen("relayUpdate", func(a): update_received.emit(a[0]))
	_listen("message", func(a): message_received.emit(a[0]))
	_listen("draw", func(a): draw_received.emit(a[0]))

	var details_cb := JavaScriptBridge.create_callback(_on_details)
	_callbacks.append(details_cb)
	_im.fetchDetails(details_cb)

func join_session() -> void:
	_emit("join", [LaunchParams.session_id, LaunchParams.client_id])

func leave_session() -> void:
	_emit("leave", [LaunchParams.session_id, LaunchParams.client_id])

func request_state_catchup() -> void:
	_emit("state", [{
		"session_id": LaunchParams.session_id,
		"client_id": LaunchParams.client_id,
		"version": 2,
	}])

func send_update(data: Variant) -> void:
	_emit("update", [data])

func send_message(data: Variant) -> void:
	_emit("message", [data])

func start_recording() -> void:
	_emit("start_recording", [LaunchParams.session_id])

func stop_recording() -> void:
	_emit("end_recording", [LaunchParams.session_id])

func _emit(event: String, args: Array) -> void:
	if _im:
		_im.emit(event, JSON.stringify(args))

func _listen(event: String, handler: Callable) -> void:
	# immersity.js passes each event's arguments as one JSON-encoded array.
	var cb := JavaScriptBridge.create_callback(func(js_args):
		handler.call(JSON.parse_string(js_args[0]))
	)
	_callbacks.append(cb)
	_im.on(event, cb)

func _on_details(js_args: Array) -> void:
	var details = JSON.parse_string(js_args[0])
	if details is Dictionary:
		details_received.emit(details)
