// ImmersityXR launch-contract glue for the Godot web export.
//
// Ported from the Unity WebGL template
// (immersityxr-unity: KomodoWebXRFullView2020/relay.js). Implements the
// engine-agnostic boundary: launch URL parameters, shared-secret auth
// forwarding, the portal lab-details fetch, and the Socket.IO 4.x /sync
// connection. The Godot client talks to this via JavaScriptBridge as
// window.ImmersityXR — see addons/immersity/relay.gd.

(function () {
  "use strict";

  var query = new URLSearchParams(window.location.search);

  var ImmersityXR = {
    params: {
      session: Number(query.get("session")) || 0,
      client: Number(query.get("client")) || 0,
      teacher: Number(query.get("teacher")) || 0,
      playback: Number(query.get("playback")) || 0,
      auth: query.get("auth") || ""
    },

    details: null, // populated by fetchDetails()
    sync: null,    // Socket.IO socket for the /sync namespace

    // Connect to the relay's /sync namespace, forwarding the page's `auth`
    // parameter so relays configured with config.auth.clientSecret accept us.
    connectSync: function () {
      if (ImmersityXR.sync) {
        return;
      }

      var url = (window.RELAY_BASE_URL || window.location.origin) + "/sync";

      if (ImmersityXR.params.auth) {
        url += "?auth=" + encodeURIComponent(ImmersityXR.params.auth);
      }

      ImmersityXR.sync = io(url);
    },

    // Register a relay event handler. The payload is passed to `callback`
    // as a JSON string, because Godot's JavaScriptBridge marshals strings
    // reliably but not arbitrary JS objects.
    on: function (event, callback) {
      ImmersityXR.sync.on(event, function () {
        callback(JSON.stringify(Array.prototype.slice.call(arguments)));
      });
    },

    // Emit a relay event. `jsonArgs` is a JSON-encoded array of arguments.
    emit: function (event, jsonArgs) {
      var args = JSON.parse(jsonArgs);
      ImmersityXR.sync.emit.apply(ImmersityXR.sync, [event].concat(args));
    },

    // Fetch lab details (session metadata + asset list) from the portal
    // API, as the Unity template does. `callback` receives a JSON string,
    // or "null" when the API is unreachable or unconfigured.
    fetchDetails: function (callback) {
      if (!window.API_BASE_URL) {
        callback("null");
        return;
      }

      fetch(window.API_BASE_URL + "/labs/" + ImmersityXR.params.session)
        .then(function (res) { return res.json(); })
        .then(function (res) {
          ImmersityXR.details = res;
          callback(JSON.stringify(res));
        })
        .catch(function (err) {
          console.error("ImmersityXR: lab details fetch failed:", err);
          callback("null");
        });
    }
  };

  window.ImmersityXR = ImmersityXR;
})();
