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
gradle = "\n".join(line for line in gradle.splitlines() if not line.strip().startswith(("def keystorePropertiesFile", "def keystoreProperties =", "keystoreProperties.load("))) + "\n"
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

# Keep the WebView inspectable in debug builds so startup failures can be diagnosed.
config["android"]["webContentsDebuggingEnabled"] = True
config_path.write_text(json.dumps(config, indent=2) + "\\n")

# A visible boot fallback prevents a failed WebView bundle from looking like a blank app.
index_path = renderer / "index.html"
index = index_path.read_text().replace("#0a0a0c", "#100d18")
boot_markup = """<div id="root">
      <div id="gamevault-boot" style="min-height:100vh;display:grid;place-items:center;background:#100d18;color:#f5f3ff;font-family:Arial,sans-serif;padding:28px;box-sizing:border-box;text-align:center">
        <div><div style="font-size:26px;font-weight:800;letter-spacing:1px">GAMEVAULT</div><p style="color:#b9aecf">Đang khởi động GameVault Cloud…</p><p style="font-size:13px;color:#8f86a3">Nếu màn hình này không tự chuyển, ứng dụng sẽ hiển thị hướng dẫn kiểm tra thay vì màn hình đen.</p></div>
      </div>
    </div>
    <script>
      (function () {
        var root = document.getElementById("root");
        function showBootError(message) {
          if (!root || root.dataset.ready === "1") return;
          var panel = document.getElementById("gamevault-boot");
          if (!panel) return;
          panel.innerHTML = "";
          var title = document.createElement("div");
          title.style.cssText = "font-size:24px;font-weight:800;margin-bottom:12px";
          title.textContent = "GameVault chưa khởi động được";
          var detail = document.createElement("p");
          detail.style.cssText = "max-width:520px;color:#c4b5fd;overflow-wrap:anywhere";
          detail.textContent = message || "Không tải được giao diện. Hãy thử mở lại ứng dụng.";
          var hint = document.createElement("p");
          hint.style.cssText = "font-size:13px;color:#9b92ad";
          hint.textContent = "Nếu lỗi tiếp tục, hãy gửi ảnh màn hình này cho nhóm phát triển.";
          panel.append(title, detail, hint);
        }
        window.addEventListener("error", function (event) {
          showBootError(event.message || "Lỗi JavaScript khi tải ứng dụng.");
        });
        window.addEventListener("unhandledrejection", function (event) {
          var reason = event.reason;
          showBootError(reason && reason.message ? reason.message : "Lỗi khởi tạo ứng dụng.");
        });
        window.setTimeout(function () {
          if (root && root.dataset.ready !== "1") {
            showBootError("Giao diện không phản hồi sau 12 giây. Hãy kiểm tra Android System WebView/Chrome và thử khởi động lại.");
          }
        }, 12000);
      })();
    </script>"""
index = index.replace('<div id="root"></div>', boot_markup)
index_path.write_text(index)

# Catch React render failures and show a readable diagnostic screen.
main_path = renderer / "src/main.tsx"
main = main_path.read_text()
main = main.replace(
    'ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(\\n  <React.StrictMode>\\n    <App />\\n  </React.StrictMode>,\\n);',
    '''class StartupErrorBoundary extends React.Component<
  React.PropsWithChildren,
  { error: string | null }
> {
  state = { error: null as string | null };

  static getDerivedStateFromError(error: unknown) {
    return { error: error instanceof Error ? error.message : String(error) };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error("[GameVault] React startup error", error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{ minHeight: "100vh", display: "grid", placeItems: "center", padding: 24, background: "#100d18", color: "#f5f3ff", fontFamily: "Arial, sans-serif" }}>
          <div style={{ maxWidth: 560 }}>
            <h1>GameVault chưa thể mở giao diện</h1>
            <p style={{ color: "#c4b5fd", overflowWrap: "anywhere" }}>{this.state.error}</p>
            <p style={{ color: "#9b92ad", fontSize: 13 }}>Hãy gửi nội dung lỗi này cho nhóm phát triển để kiểm tra.</p>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

const rootElement = document.getElementById("root") as HTMLElement;
ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <StartupErrorBoundary>
      <App />
    </StartupErrorBoundary>
  </React.StrictMode>,
);
rootElement.dataset.ready = "1";'''
)
main_path.write_text(main)
PY

echo "GameVault Android identity prepared."
