#!/usr/bin/env bash
set -euo pipefail

ROOT="engine/opennow-stable"
test -d "$ROOT/android/app" || { echo "Android engine submodule is missing. Run git submodule update --init --recursive."; exit 1; }

python3 - <<'PY'
from pathlib import Path
import json, re

root = Path("engine/opennow-stable")

# Capacitor identity.
config_path = root / "capacitor.config.json"
config = json.loads(config_path.read_text())
config["appId"] = "com.gamevault.cloud"
config["appName"] = "GameVault Cloud"
config.setdefault("server", {})["androidScheme"] = "https"
config_path.write_text(json.dumps(config, indent=2) + "\n")

# Remove a developer-machine-only release keystore reference. CI builds the
# standard Android debug APK, which is signed with the Android debug key.
gradle_path = root / "android/app/build.gradle"
gradle = gradle_path.read_text()
gradle = re.sub(r'^def keystorePropertiesFile = .*?\n.*?keystoreProperties\.load\(new FileInputStream\(keystorePropertiesFile\)\)\n\n', '', gradle, flags=re.M)
gradle = re.sub(r'\n    signingConfigs \{\n        release \{.*?\n        \}\n    \}\n', '\n', gradle, flags=re.S)
gradle = gradle.replace('            signingConfig signingConfigs.release\n', '')
gradle = gradle.replace('namespace = "com.zortos.opennow"', 'namespace = "com.gamevault.cloud"')
gradle = gradle.replace('applicationId "com.zortos.opennow"', 'applicationId "com.gamevault.cloud"')
gradle_path.write_text(gradle)

# App name, package metadata, and OAuth return scheme.
strings_path = root / "android/app/src/main/res/values/strings.xml"
strings = strings_path.read_text()
strings = strings.replace(">OpenNOW<", ">GameVault Cloud<")
strings = strings.replace("com.zortos.opennow.android", "com.gamevault.cloud")
strings_path.write_text(strings)

manifest_path = root / "android/app/src/main/AndroidManifest.xml"
manifest = manifest_path.read_text().replace('android:scheme="opennow"', 'android:scheme="gamevault"')
manifest_path.write_text(manifest)

activity_path = root / "android/app/src/main/java/com/zortos/opennow/MainActivity.kt"
activity = activity_path.read_text().replace('uri.scheme == "opennow"', 'uri.scheme == "gamevault"')
activity_path.write_text(activity)

plugin_path = root / "android/app/src/main/java/com/zortos/opennow/GfnPlugin.kt"
plugin = plugin_path.read_text().replace('opennow_auth', 'gamevault_auth').replace('opennow_settings', 'gamevault_settings')
plugin_path.write_text(plugin)

# Rebrand visible renderer text without changing the upstream API symbols.
renderer = root / "src/renderer"
for path in renderer.rglob("*"):
    if path.is_file() and path.suffix in {".tsx", ".ts", ".html", ".json"}:
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        updated = text.replace("OpenNOW", "GameVault Cloud")
        if updated != text:
            path.write_text(updated)

# Give the streaming client a separate GameVault visual identity.
css_path = renderer / "src/styles.css"
css = css_path.read_text()
for old, new in {
    "#58d98a": "#a78bfa",
    "#6ae89a": "#c4b5fd",
    "#44c477": "#8b5cf6",
    "rgba(88, 217, 138, 0.25)": "rgba(167, 139, 250, 0.25)",
    "rgba(88, 217, 138, 0.08)": "rgba(167, 139, 250, 0.08)",
    "rgba(88, 217, 138, 0.14)": "rgba(167, 139, 250, 0.14)",
    "#062315": "#21133d",
    "#1a2a22": "#251d3d",
}.items():
    css = css.replace(old, new)
css = css.replace("rgba(88, 217, 138,", "rgba(167, 139, 250,")
css_path.write_text(css)

index_path = renderer / "index.html"
index = index_path.read_text().replace("#0a0a0c", "#100d18")
index_path.write_text(index)
PY

echo "GameVault Android identity prepared."
