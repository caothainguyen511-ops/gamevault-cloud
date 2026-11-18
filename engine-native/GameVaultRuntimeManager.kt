package com.gamevault.nativeemulator

import android.content.Context
import android.os.Build
import org.json.JSONObject
import java.io.File

/**
 * Owns only app-private runtime state. Runtime binaries are not bundled yet.
 * A prefix is created only after the Android storage location is validated.
 */
class GameVaultRuntimeManager(private val context: Context) {
    private val runtimeDir = File(context.filesDir, "gamevault/runtime")
    private val prefixesDir = File(context.filesDir, "gamevault/prefixes")

    data class Capabilities(
        val androidApi: Int,
        val supportedAbi: String,
        val runtimeInstalled: Boolean,
        val wineAvailable: Boolean,
        val box64Available: Boolean,
        val box86Available: Boolean,
        val graphicsBackendAvailable: Boolean,
        // Kept false until a real, tested process launcher is included.
        val canLaunchExe: Boolean,
        val prefixReady: Boolean,
        val status: String,
        val message: String
    )

    fun capabilities(): Capabilities {
        val abi = Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"
        val wine = File(runtimeDir, "wine/bin/wine").canExecute()
        val box64 = File(runtimeDir, "bin/box64").canExecute()
        val box86 = File(runtimeDir, "bin/box86").canExecute()
        val graphics = File(runtimeDir, "graphics/backend.json").isFile
        val manifest = File(runtimeDir, "runtime-manifest.json")
        val manifestValid = runCatching {
            val json = JSONObject(manifest.readText())
            json.optInt("schemaVersion") == 1 &&
                json.optString("architecture") == abi &&
                json.optBoolean("licenseAuditComplete") &&
                json.optBoolean("runtimeTested")
        }.getOrDefault(false)
        val runtimeReady = Build.VERSION.SDK_INT >= 26 && wine && box64 && graphics && manifestValid
        val prefixReady = File(prefixesDir, "default/drive_c").isDirectory
        val message = when {
            Build.VERSION.SDK_INT < 26 -> "Android 8.0 or newer is required."
            !runtimeReady -> "Native runtime files are not installed or have not passed the runtime manifest checks."
            else -> "Runtime components detected. EXE launching remains disabled until the process launcher is integrated and device-tested."
        }
        return Capabilities(
            androidApi = Build.VERSION.SDK_INT,
            supportedAbi = abi,
            runtimeInstalled = runtimeReady,
            wineAvailable = wine,
            box64Available = box64,
            box86Available = box86,
            graphicsBackendAvailable = graphics,
            canLaunchExe = false,
            prefixReady = prefixReady,
            status = if (runtimeReady) "runtime_detected_launcher_pending" else "runtime_not_installed",
            message = message
        )
    }

    @Synchronized
    fun initializeDefaultPrefix(): File {
        check(Build.VERSION.SDK_INT >= 26) { "Android 8.0 or newer is required." }
        val root = File(prefixesDir, "default").canonicalFile
        check(root.path.startsWith(prefixesDir.canonicalPath + File.separator)) {
            "Invalid prefix path."
        }
        listOf(
            "drive_c",
            "drive_c/Program Files",
            "drive_c/users/gamevault",
            "dosdevices",
            "temp"
        ).forEach { relative ->
            val dir = File(root, relative)
            check(dir.canonicalFile.path.startsWith(root.path + File.separator) || dir.canonicalFile == root)
            if (!dir.exists() && !dir.mkdirs()) error("Could not create prefix directory: $relative")
            check(dir.isDirectory) { "Prefix path is not a directory: $relative" }
        }
        File(root, "prefix-info.json").writeText(
            JSONObject()
                .put("schemaVersion", 1)
                .put("createdBy", "GameVault")
                .put("androidApi", Build.VERSION.SDK_INT)
                .put("architecture", Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown")
                .toString(2)
        )
        return root
    }
}
