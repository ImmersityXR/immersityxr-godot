# ImmersityXR Godot Template

A [Godot 4](https://godotengine.org/) client template for
[ImmersityXR](https://github.com/ImmersityXR/immersityxr-core), the multi-user
WebXR education platform. It implements the same engine-agnostic contract
as the Unity client
([immersityxr-unity](https://github.com/ImmersityXR/immersityxr-unity)):
launch URL parameters, the portal lab-details API, and the relay's
Socket.IO `/sync` protocol — documented in
[docs/PROTOCOL.md](docs/PROTOCOL.md).

> **Status: early scaffold.** The bridge and protocol layers are in place
> but have not yet been exercised against a live relay. Expect iteration.

## How it works

```
Portal iframe ──launch URL──► index.html (Godot web export)
                                │  head_include loads:
                                │  config.js · socket.io.js (v2.3) · immersity.js
                                │        │
                                │        └── window.ImmersityXR: params, auth
                                │            forwarding, /sync socket, lab fetch
                                ▼
                          Godot (GDScript)
                          LaunchParams / Relay autoloads
                          (addons/immersity/, via JavaScriptBridge)
```

The JS boundary layer is ported from the Unity WebGL template — both
engines' web exports are plain HTML/JS around a canvas, so the
relay/launch glue transfers almost verbatim. Server URLs live in
`web/config.js`, which is copied next to `index.html` at export time and
can be edited in a deployed build folder without re-exporting.

## Development

Requirements: Godot 4.4+.

1. Open the project in the Godot editor. In the editor (non-web) the
   `Relay` autoload is inert and `LaunchParams` uses its `editor_*`
   defaults, so scenes run without any servers.
2. To test against a real stack, export for Web and serve the build from
   the ImmersityXR build server (or any static server behind the relay's
   allowed origins), then open:
   `.../index.html?session=1001&client=1&teacher=1`

### Export

```bash
godot --headless --export-release "Web" build/web/index.html
cp web/config.js web/socket.io.js web/immersity.js build/web/
```

CI does this on every tag and attaches a zip to a GitHub Release —
deployable by the existing
[deploy flow](https://github.com/ImmersityXR/immersityxr-core/tree/main/deploy)
(download release zip into `immersity-buildserver/builds/`), side by side
with Unity builds.

## Layout

| Path | Purpose |
|---|---|
| `addons/immersity/` | `LaunchParams` and `Relay` autoloads (JavaScriptBridge glue) |
| `web/` | JS boundary layer bundled into the export |
| `scenes/` | Template scene: session join, remote clients, WebXR entry |
| `docs/PROTOCOL.md` | The client contract, extracted from the relay source |

## Roadmap

- [ ] First end-to-end test against a deployed relay (join, update echo)
- [ ] Remote client representation (`scenes/main.gd::_on_update`)
- [ ] Runtime glTF loading from the portal asset list
- [ ] XR controllers/hands (`XROrigin3D` rig) beyond the bare session entry
- [ ] Native (non-web) transport — realistic after the platform's
      Socket.IO 4 upgrade (Phase 3 in the immersityxr-core roadmap)
