extends Node
## Autoload "LaunchParams" — the Immersity launch URL contract.
##
## The portal iframes the build at
## {BUILD_URL}/{scope}/{build}/?client={userId}&session={sessionId}&teacher={0|1}
## (plus playback={captureId} and auth={sharedSecret}).
## In the editor / non-web builds, values fall back to the editor_* settings
## below so scenes can be tested without the portal.

@export var editor_session_id: int = 1001
@export var editor_client_id: int = 1
@export var editor_is_teacher: bool = true

var session_id: int
var client_id: int
var is_teacher: bool
var playback_id: int

func _ready() -> void:
	if OS.has_feature("web"):
		var im: JavaScriptObject = JavaScriptBridge.get_interface("Immersity")
		session_id = int(im.params.session)
		client_id = int(im.params.client)
		is_teacher = int(im.params.teacher) == 1
		playback_id = int(im.params.playback)
	else:
		session_id = editor_session_id
		client_id = editor_client_id
		is_teacher = editor_is_teacher
		playback_id = 0
