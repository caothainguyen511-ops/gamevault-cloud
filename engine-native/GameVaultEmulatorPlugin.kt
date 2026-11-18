package com.gamevault.nativeemulator

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

/** Native bridge; it never advertises EXE execution without a real process launcher. */
@CapacitorPlugin(name = "GameVaultEmulator")
class GameVaultEmulatorPlugin : Plugin() {
    private val manager by lazy { GameVaultRuntimeManager(context) }

    @PluginMethod
    fun getCapabilities(call: PluginCall) {
        val c = manager.capabilities()
        val result = JSObject()
        result.put("androidApi", c.androidApi)
        result.put("supportedAbi", c.supportedAbi)
        result.put("runtimeInstalled", c.runtimeInstalled)
        result.put("wineAvailable", c.wineAvailable)
        result.put("box64Available", c.box64Available)
        result.put("box86Available", c.box86Available)
        result.put("graphicsBackendAvailable", c.graphicsBackendAvailable)
        result.put("canLaunchExe", c.canLaunchExe)
        result.put("prefixReady", c.prefixReady)
        result.put("status", c.status)
        result.put("message", c.message)
        call.resolve(result)
    }

    @PluginMethod
    fun initializePrefix(call: PluginCall) {
        try {
            val prefix = manager.initializeDefaultPrefix()
            val result = JSObject()
            result.put("ready", true)
            result.put("path", prefix.absolutePath)
            result.put("message", "GameVault's private Windows prefix has been initialized.")
            call.resolve(result)
        } catch (error: Exception) {
            call.reject(error.message ?: "Could not initialize the emulator prefix.", "PREFIX_INIT_FAILED")
        }
    }

    @PluginMethod
    fun launchExe(call: PluginCall) {
        call.reject(
            "The local Windows process launcher is not included in this build. Cloud gaming remains available.",
            "LAUNCHER_NOT_AVAILABLE"
        )
    }
}
