# Native Windows runtime integration status

## Implemented in the Android bridge

- A native runtime manager checks Android API/ABI and looks for the expected app-private Wine, Box64/Box86, graphics-backend, and runtime-manifest files.
- Runtime claims are fail-closed: missing binaries, mismatched ABI, an incomplete license/test manifest, or an absent graphics backend keep local execution unavailable.
- GameVault can initialize a per-device Windows-style prefix under app-private storage. It creates the initial C: drive, user, dosdevices, and temp directories without requesting broad storage access.
- The Capacitor bridge exposes capability diagnostics and prefix initialization to the Windows page.
- EXE launching remains explicitly disabled because the Wine/Box64 process runner and a device-tested graphics path are not present.

## Still required for real Windows game execution

This is **not yet Wine/Box64 integration**. The next implementation phase must select compatible Wine + Box64/Box86 source revisions, build their Android arm64 libraries with NDK, choose and validate a graphics backend, preserve upstream licenses, implement a sandboxed process runner, handle Android document-picker URIs, and test on real devices. Runtime binaries are not downloaded from opaque APKs and no proprietary Windows game files are bundled.

Cloud/WebRTC remains the available play path. A successful Android build validates the app and bridge only; it does not prove that Windows EXE files can run.
