# Native Windows runtime integration status

The Android build now contains a registered Capacitor native capability bridge. It reports device ABI/API and, importantly, reports the Windows runtime as unavailable. The EXE launch method fails closed instead of pretending to start a game.

This is **not Wine/Box64 integration**. The next implementation phase must select compatible Wine + Box64/Box86 source revisions, build their Android arm64 libraries with NDK, choose a graphics backend, preserve all upstream licenses, initialize per-game prefixes in app-private storage, and test on real devices. No opaque runtime APKs or copyrighted game payloads are bundled.

Cloud/WebRTC remains the playable path in the meantime.
