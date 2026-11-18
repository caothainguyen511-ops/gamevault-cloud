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
