# ImmersityXR Client Contract

What any engine client (Unity, Godot, …) must implement to participate in
an ImmersityXR session. Ground truth is `services/relay/sync.js` in
[immersityxr-core](https://github.com/ImmersityXR/immersityxr-core); event
names below were extracted from it (July 2026).

## 1. Launch URL

The portal iframes the build (with `allow="xr-spatial-tracking"`) at:

```
{BUILD_URL}/{scope}/{build}/?client={userId}&session={sessionId}&teacher={0|1}
```

Optional parameters:

| Param | Meaning |
|---|---|
| `playback={captureId}` | Launch in capture-replay mode |
| `auth={secret}` | Shared secret, forwarded to the relay as `?auth=` on the Socket.IO connection (required when the relay sets `config.auth.clientSecret`) |

## 2. Portal REST API

`GET {API_BASE_URL}/labs/{session_id}` returns session metadata and the
asset list: `session_id`, `session_name`, `course_id`, `description`,
`start_time`, `end_time`, `users`, and `assetList[]` with `asset_id`,
`asset_name`, `path` (URL to a glTF, typically S3), `is_whole_object`,
`scale`.

## 3. Relay: Socket.IO 2.x, namespace `/sync`

The relay runs **Socket.IO 2.x** (server 2.3); clients must use a
matching-protocol client. This template uses the same `socket.io.js` v2.3.0
the Unity WebGL template ships.

### Client → server

| Event | Payload | Purpose |
|---|---|---|
| `join` | `[session_id, client_id]` | Join a session |
| `leave` | `[session_id, client_id]` | Leave a session |
| `state` | `{ session_id, client_id, version }` | Request state catch-up (late join / rejoin) |
| `update` | position/entity payload (relayed verbatim) | Sync state to peers |
| `interact` | interaction payload | Interaction events (also journaled to captures) |
| `draw` | stroke payload | Whiteboard/draw strokes (stored in session state) |
| `message` | typed packet | General message channel |
| `sessionInfo` | `session_id` | Request session info |
| `start_recording` / `end_recording` | `session_id` | Research capture control |
| `playback` | capture ref | Capture replay control |

### Server → client

| Event | Payload | Meaning |
|---|---|---|
| `serverName` | string | Sent on connect |
| `successfullyJoined` / `failedToJoin` | `session_id` (+ `reason`) | Join result for *this* client |
| `joined` / `left` / `disconnected` | `client_id` | Peer lifecycle |
| `successfullyLeft` / `failedToLeave` | `session_id` (+ `reason`) | Leave result |
| `state` | versioned state object (entities, scene) | Catch-up response; draw strokes are replayed as separate `draw` events |
| `relayUpdate` | payload from a peer's `update` | Peer state sync |
| `interactionUpdate` | interaction payload | Peer interactions |
| `draw` / `message` / `sessionInfo` | as sent | Relayed events |
| `bump` | `session_id` | This client was bumped (duplicate connection) |
| `rejectUser` | `reason` | Auth/authorization rejection |
| `connectionError` / `stateError` | message | Errors |

### Auth

Append `?auth={secret}` to the namespace connection URL. Relays configured
with `config.auth.clientSecret` reject connections without it
(deny-by-default applies to `/admin`; `/sync` and `/chat` enforce when the
secret is set).

## 4. Other namespaces (not yet used by this template)

- `/chat` — chat + (experimental) media signaling
- `/rtc` — WebRTC voice/video signaling (Socket.IO rooms per session,
  server-provided ICE config)
- `/admin` — monitoring; requires `adminSecret`
