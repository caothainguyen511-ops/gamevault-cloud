# GameVault Cloud

GameVault Cloud is an independent Android cloud-gaming client. The Android APK is built from the Android GeForce NOW client engine in the pinned `engine` submodule, with GameVault branding and a separately restyled interface.

## What it does

- Sign in with your own supported GeForce NOW account.
- Load the provider catalog and your game library.
- Create and manage cloud sessions.
- Stream gameplay through Android WebRTC.
- Use touch controls and configure stream quality, resolution, FPS, codec, and region where supported.

Availability and performance depend on the account, provider region, network, Android device, and the games supported by the cloud service. GameVault Cloud is unofficial and is not affiliated with, endorsed by, or sponsored by NVIDIA.

## Build the Android app

The GitHub Actions workflow builds a debug APK automatically when code is pushed to `main`. Open **Actions → GameVault Cloud Android → latest successful run** and download the `GameVault-Cloud-playable-debug-apk` artifact.

To build locally, initialize the submodule and follow the Android build workflow:

```bash
git submodule update --init --recursive
bash scripts/prepare-gamevault.sh
cd engine/opennow-stable
npm install
npm run build
npx cap sync android
cd android
./gradlew assembleDebug
```

## Source and license

The cloud-session, authentication, signaling, and WebRTC implementation is sourced from [OpenNow-Android](https://github.com/priyanshrv1-oss/OpenNow-Android), branch `Android`, pinned to commit `6703650c20a8f97ccbe83a8ecd6bacf27cba1eb6`. That source is distributed under the MIT License; its original copyright and license notice are retained in the submodule and in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

GameVault branding and the Android build configuration are maintained separately in this repository. The web preview in the repository root is a UI prototype; use the Android APK artifact for the integrated streaming client.
