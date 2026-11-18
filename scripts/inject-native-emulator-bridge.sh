#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID="$ROOT/engine/opennow-stable/android"
RENDERER="$ROOT/engine/opennow-stable/src/renderer/src"
PLUGIN="$ANDROID/app/src/main/java/com/gamevault/nativeemulator/GameVaultEmulatorPlugin.kt"
ACTIVITY="$ANDROID/app/src/main/java/com/zortos/opennow/MainActivity.kt"

mkdir -p "$(dirname "$PLUGIN")" "$RENDERER/native" "$RENDERER/components"
cat > "$PLUGIN" <<'KOTLIN'
package com.gamevault.nativeemulator

import android.os.Build
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

/** Reports actual runtime capabilities; never claims EXE support without Wine/Box64. */
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
        result.put("message", "Windows runtime is not installed in this build. Cloud gaming remains available.")
        call.resolve(result)
    }

    @PluginMethod
    fun launchExe(call: PluginCall) {
        call.reject(
            "Local EXE launch is disabled until Wine, the architecture translator, and graphics backend are integrated and tested.",
            "RUNTIME_NOT_INSTALLED"
        )
    }
}
KOTLIN

python3 - "$ACTIVITY" "$RENDERER" <<'PY'
from pathlib import Path
import sys
activity = Path(sys.argv[1])
renderer = Path(sys.argv[2])
s = activity.read_text()
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
activity.write_text(s)

native = renderer / "native" / "GameVaultEmulator.ts"
native.write_text("""import { registerPlugin } from "@capacitor/core";

export interface EmulatorCapabilities {
  androidApi: number;
  supportedAbi: string;
  runtimeInstalled: boolean;
  wineAvailable: boolean;
  box64Available: boolean;
  box86Available: boolean;
  graphicsBackendAvailable: boolean;
  canLaunchExe: boolean;
  status: string;
  message: string;
}

interface GameVaultEmulatorPlugin {
  getCapabilities(): Promise<EmulatorCapabilities>;
  launchExe(options: { uri: string }): Promise<void>;
}

export const GameVaultEmulator = registerPlugin<GameVaultEmulatorPlugin>("GameVaultEmulator");
""")

page = renderer / "components" / "LocalEmulatorPage.tsx"
page.write_text("""import { useCallback, useEffect, useState } from "react";
import { AlertTriangle, Cpu, RefreshCw, ShieldCheck } from "lucide-react";
import type { JSX } from "react";
import { GameVaultEmulator, type EmulatorCapabilities } from "../native/GameVaultEmulator";

export function LocalEmulatorPage(): JSX.Element {
  const [capabilities, setCapabilities] = useState<EmulatorCapabilities | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setCapabilities(await GameVaultEmulator.getCapabilities());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Native emulator bridge is unavailable.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void refresh(); }, [refresh]);

  return (
    <section className="settings-page" style={{ padding: 24, maxWidth: 900, margin: "0 auto" }}>
      <header style={{ marginBottom: 24 }}>
        <h1>Windows Emulator</h1>
        <p>Local runtime status on this Android device. Cloud streaming remains available separately.</p>
      </header>
      <div style={{ border: "1px solid var(--border-color, #444)", borderRadius: 14, padding: 20, marginBottom: 18 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
          <Cpu size={22} />
          <strong>Device compatibility</strong>
        </div>
        {loading ? <p>Checking native capabilities…</p> : error ? (
          <p role="alert">{error}</p>
        ) : capabilities ? (
          <>
            <p><b>Android API:</b> {capabilities.androidApi}</p>
            <p><b>CPU ABI:</b> {capabilities.supportedAbi}</p>
            <p><b>Wine:</b> {capabilities.wineAvailable ? "Available" : "Not installed"}</p>
            <p><b>Box64:</b> {capabilities.box64Available ? "Available" : "Not installed"}</p>
            <p><b>Box86:</b> {capabilities.box86Available ? "Available" : "Not installed"}</p>
            <p><b>Graphics backend:</b> {capabilities.graphicsBackendAvailable ? "Available" : "Not configured"}</p>
            <p><b>EXE launch:</b> {capabilities.canLaunchExe ? "Ready" : "Unavailable"}</p>
            <p>{capabilities.message}</p>
          </>
        ) : <p>Native capability information is unavailable.</p>}
        <button type="button" onClick={() => void refresh()} disabled={loading} style={{ marginTop: 10 }}>
          <RefreshCw size={15} /> Refresh device check
        </button>
      </div>
      <div style={{ border: "1px solid var(--border-color, #444)", borderRadius: 14, padding: 20 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <AlertTriangle size={20} />
          <strong>Runtime integration still in progress</strong>
        </div>
        <p>Wine, Box64/Box86 and a compatible graphics backend are not bundled yet. Local EXE launch is deliberately disabled; this screen does not pretend that Windows games can already run.</p>
        <p><ShieldCheck size={15} /> Your existing OpenNow/WebRTC cloud mode is unchanged.</p>
      </div>
    </section>
  );
}
""")

app = renderer / "App.tsx"
s = app.read_text()
s = s.replace('import { SettingsPage } from "./components/SettingsPage";',
              'import { SettingsPage } from "./components/SettingsPage";\nimport { LocalEmulatorPage } from "./components/LocalEmulatorPage";', 1)
s = s.replace('type AppPage = "home" | "library" | "settings";',
              'type AppPage = "home" | "library" | "settings" | "local";', 1)
s = s.replace('const APP_PAGE_ORDER: AppPage[] = ["home", "library", "settings"];',
              'const APP_PAGE_ORDER: AppPage[] = ["home", "library", "settings", "local"];', 1)
anchor = """        {currentPage === "settings" && (
          <SettingsPage
            settings={settings}
            regions={regions}
            onSettingChange={updateSetting}
            user={authSession.user}
            subscription={subscriptionInfo}
            onLogout={handleLogout}
          />
        )}"""
if anchor not in s:
    raise SystemExit("Cannot safely patch App.tsx: SettingsPage render block not found")
s = s.replace(anchor, anchor + '\n\n        {currentPage === "local" && <LocalEmulatorPage />}', 1)
app.write_text(s)

navbar = renderer / "components" / "Navbar.tsx"
s = navbar.read_text()
s = s.replace('import { LayoutGrid, Library, Settings, Loader2, PlayCircle } from "lucide-react";',
              'import { LayoutGrid, Library, Settings, Loader2, PlayCircle, MonitorCog } from "lucide-react";', 1)
s = s.replace('currentPage: "home" | "library" | "settings";',
              'currentPage: "home" | "library" | "settings" | "local";', 1)
s = s.replace('onNavigate: (page: "home" | "library" | "settings") => void;',
              'onNavigate: (page: "home" | "library" | "settings" | "local") => void;', 1)
anchor = '    { id: "settings" as const, label: "Settings", icon: Settings },'
if anchor not in s:
    raise SystemExit("Cannot safely patch Navbar.tsx: settings nav item not found")
s = s.replace(anchor, anchor + '\n    { id: "local" as const, label: "Windows", icon: MonitorCog },', 1)
navbar.write_text(s)
PY

echo "GameVault Windows page + native capability bridge injected; EXE launch remains safely disabled until runtime binaries exist."
