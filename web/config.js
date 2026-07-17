// Deployment configuration for the Immersity Godot web build.
//
// Like the Unity template's relay.js, this file is loaded by the exported
// page at runtime and can be edited inside a build folder without
// re-exporting — ops can retarget a deployed build by editing this file.
//
// Defaults assume the build is served by the Immersity build server behind
// Traefik, where the relay is routed on the same origin.

window.RELAY_BASE_URL = window.location.origin;
window.API_BASE_URL = "";   // e.g. "https://api.yourdomain.edu" — empty disables the lab-details fetch
