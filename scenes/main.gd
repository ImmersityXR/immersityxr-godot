extends Node3D
## Template main scene: joins the Immersity session on load and keeps a
## node per remote client under $RemoteClients.

func _ready() -> void:
	Relay.joined.connect(_on_joined)
	Relay.join_failed.connect(func(sid, reason): push_error("Join failed for session %d: %s" % [sid, reason]))
	Relay.client_joined.connect(_on_client_joined)
	Relay.client_left.connect(_on_client_gone)
	Relay.client_disconnected.connect(_on_client_gone)
	Relay.state_received.connect(_on_state)
	Relay.update_received.connect(_on_update)
	Relay.details_received.connect(func(details): print("Lab: ", details.get("session_name", "?")))

	Relay.join_session()

func _on_joined(session_id: int) -> void:
	print("Joined session ", session_id)
	Relay.request_state_catchup()

func _on_state(state) -> void:
	# Late-join catch-up: entities/scene/strokes recorded by the relay.
	print("State catch-up: ", state)

func _on_client_joined(client_id: int) -> void:
	print("Client joined: ", client_id)

func _on_client_gone(client_id: int) -> void:
	var node := $RemoteClients.get_node_or_null(str(client_id))
	if node:
		node.queue_free()

func _on_update(data) -> void:
	# TODO(template author): apply a remote client's update to the scene.
	#
	# This is the core design decision of the template: how remote
	# participants are represented. The relay forwards `update` payloads
	# verbatim (see docs/PROTOCOL.md), so this function decides:
	#   - spawn-on-first-sight (create a node under $RemoteClients keyed by
	#     client/entity id) vs. pre-registered scene entities
	#   - snap to received transforms vs. interpolate between them
	# The Unity client interpolates head/hand transforms per client.
	pass
