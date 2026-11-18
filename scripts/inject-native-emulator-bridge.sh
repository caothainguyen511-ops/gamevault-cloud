#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID="$ROOT/engine/opennow-stable/android"
PLUGIN="$ANDROID/app/src/main/java/com/gamevault/nativeemulator/GameVaultEmulatorPlugin.kt"
ACTIVITY="$ANDROID/app/src/main/java/com/zortos/opennow/MainActivity.kt"

mkdir -p "$(dirname "$PLUGIN")"
cat > "$PLUGIN" <<'KOTLIN'
package com.gamevault.nativeemulator

import android.os.Build
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

/**
 * Capability gate for the optional local Windows runtime.
 *
 * This deliberately does not claim that Wine/Box64 is installed. The runtime
 * remains disabled until compatible, licensed native binaries and a tested
 * graphics backend are shipped by a later integration.
 */
@CapacitorPlugin(name = "GameVaultEmulator")
class GameVaultEmulatorPlugin : Plugin() {
    @PluginMethod
    fun getCapabilities(call: PluginCall) {
        val result = JSObject()
        result.put("androidApi", Build.VERSION.SDK_INT)
        result.put("supportedAbi", Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown")
        result.put("runtimeInstalled", false)
        result.put("wineAvailable", false)
        result.put("box64Available", false)
        result.put("box86Available", false)
        result.put("graphicsBackendAvailable", false)
        result.put("canLaunchExe", false)
        result.put("status", "runtime_not_integrated")
        result.put(
            "message",
            "Windows runtime is not installed in this build. Cloud gaming remains available."
        )
        call.resolve(result)
    }

    @PluginMethod
    fun launchExe(call: PluginCall) {
        val result = JSObject()
        result.put("code", "RUNTIME_NOT_INSTALLED")
        result.put(
            "message",
            "Local EXE launch is disabled until Wine, the architecture translator, and graphics backend are integrated and tested."
        )
        call.reject(result.getString("message"), "RUNTIME_NOT_INSTALLED")
    }
}
KOTLIN

python3 - "$ACTIVITY" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
imp = "import com.gamevault.nativeemulator.GameVaultEmulatorPlugin"
if imp not in s:
    anchor = "import com.getcapacitor.BridgeActivity"
    if anchor not in s:
        raise SystemExit("Cannot safely patch MainActivity: BridgeActivity import not found")
    s = s.replace(anchor, anchor + "\n" + imp, 1)
reg = "registerPlugin(GameVaultEmulatorPlugin::class.java)"
if reg not in s:
    anchor = "registerPlugin(GfnPlugin::class.java)"
    if anchor not in s:
        raise SystemExit("Cannot safely patch MainActivity: GfnPlugin registration not found")
    s = s.replace(anchor, anchor + "\n        " + reg, 1)
p.write_text(s)
PY
echo "GameVault native capability bridge injected (runtime intentionally disabled)."
