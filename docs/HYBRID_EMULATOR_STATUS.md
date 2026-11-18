# GameVault Hybrid: native Windows emulator track

## Architecture decision

GameVault remains a hybrid Android app:

- **Cloud mode:** keep the pinned OpenNow Android engine, account flow, signaling, and WebRTC stream path intact.
- **Local mode:** a separate native Android runtime module, selected from the same GameVault shell, for Windows compatibility workloads.
- **Shared shell:** library, downloads, controller mapping, settings, and per-user emulator profiles remain in GameVault.

## Important implementation boundary

The current repository contains a cloud-streaming engine in the `engine` Git submodule. It does **not** contain Wine, Box64/Box86, a Windows compatibility runtime, or a tested local EXE launcher. A UI screen or a successful cloud APK build must never be reported as proof that Windows EXE execution works.

The native track must be integrated as a separately testable Android module and must preserve upstream OpenNow source and license notices. Runtime binaries must be built from compatible, legally distributable sources; do not download opaque APKs or bundle proprietary Windows files.

## Device and runtime gates

Before enabling the Windows launch action, the native module must report all of these:

1. Supported Android ABI and API level.
2. Runtime libraries present and loadable.
3. Wine prefix initialized in app-private storage.
4. Box64/Box86 architecture translation available for the selected workload.
5. Required graphics backend available on this device.
6. Game files selected by the user and readable by the app.

If any gate fails, show a clear diagnostic and keep Cloud mode available. Never show a fake FPS counter or a successful launch state.

## Delivery sequence

1. Keep Cloud/WebRTC regression-tested.
2. Add a Capacitor bridge to a native emulator manager with explicit capability reporting.
3. Integrate and license-audit Wine and the appropriate translation layer.
4. Add isolated per-game prefixes, storage permissions through Android's document picker, controller mapping, and lifecycle handling.
5. Test on arm64 physical devices at multiple memory/performance tiers.
6. Enable local launch only for combinations that pass the device/runtime gates.

## Current status

- Cloud engine: present as a pinned submodule.
- Supabase emulator profile schema: present; it stores preferences, not runtime binaries.
- Native Windows runtime: **not integrated yet**.
- EXE launch on Android: **not verified**.
- APK: must be built and tested by CI before release claims are made.
