package br.com.matheus.gree_app

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val iconNames = listOf("default", "light", "accent", "mono")

    private fun aliasOf(name: String): String =
        "$packageName.Icon" + name.replaceFirstChar { it.uppercaseChar() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gree/icon")
            .setMethodCallHandler { call, result ->
                if (call.method == "set") {
                    val name = call.argument<String>("name") ?: "default"
                    if (name !in iconNames) {
                        result.error("invalid", "ícone inválido: $name", null)
                        return@setMethodCallHandler
                    }
                    val pm = packageManager
                    for (i in iconNames) {
                        val comp = ComponentName(this, aliasOf(i))
                        val state = if (i == name) {
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                        } else {
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        }
                        pm.setComponentEnabledSetting(comp, state, PackageManager.DONT_KILL_APP)
                    }
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
