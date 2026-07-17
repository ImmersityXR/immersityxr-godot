extends Node
## Starts an immersive WebXR session when supported, per the Godot 4 WebXR
## pattern. On desktop browsers without XR the scene simply stays on the
## flat Camera3D view.

var webxr: WebXRInterface

func _ready() -> void:
	if not OS.has_feature("web"):
		return

	webxr = XRServer.find_interface("webxr")
	if not webxr:
		return

	webxr.session_supported.connect(_on_session_supported)
	webxr.session_started.connect(func(): get_viewport().use_xr = true)
	webxr.session_ended.connect(func(): get_viewport().use_xr = false)
	webxr.session_failed.connect(func(msg): push_warning("WebXR session failed: " + msg))

	webxr.is_session_supported("immersive-vr")

func _on_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode != "immersive-vr" or not supported:
		return

	# WebXR sessions must start from a user gesture; surface a simple
	# "Enter VR" flow. For now, start on the first click/tap.
	webxr.session_mode = "immersive-vr"
	webxr.requested_reference_space_types = "bounded-floor, local-floor, local"
	webxr.required_features = "local-floor"
	webxr.optional_features = "bounded-floor"

func enter_vr() -> void:
	if webxr and not webxr.initialize():
		push_warning("WebXR: failed to initialize immersive session")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		enter_vr()
