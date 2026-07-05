package br.net.mantovani.bitfinder

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newCachedThreadPool()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "native_crypto"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(NativeCrypto.isNativeAvailable())
                "getThermalStatus" -> {
                    val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val powerManager =
                            getSystemService(Context.POWER_SERVICE) as PowerManager
                        powerManager.currentThermalStatus
                    } else {
                        PowerManager.THERMAL_STATUS_NONE
                    }
                    result.success(status)
                }
                "getThermalInfo" -> {
                    val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val powerManager =
                            getSystemService(Context.POWER_SERVICE) as PowerManager
                        powerManager.currentThermalStatus
                    } else {
                        PowerManager.THERMAL_STATUS_NONE
                    }
                    val batteryIntent = registerReceiver(
                        null,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                    )
                    val rawTemperature = batteryIntent?.getIntExtra(
                        BatteryManager.EXTRA_TEMPERATURE,
                        Int.MIN_VALUE
                    ) ?: Int.MIN_VALUE
                    val temperatureCelsius = if (rawTemperature == Int.MIN_VALUE) {
                        null
                    } else {
                        rawTemperature / 10.0
                    }
                    result.success(
                        mapOf(
                            "thermalStatus" to status,
                            "batteryTemperatureCelsius" to temperatureCelsius
                        )
                    )
                }
                "searchBatch" -> {
                    val startKey = call.argument<ByteArray>("startKey")
                    val count = call.argument<Int>("count")
                    val stride = call.argument<ByteArray>("stride")
                    val compressionMode = call.argument<Int>("compressionMode")
                    val rawTargets = call.argument<List<ByteArray>>("targetHashes")

                    if (startKey == null || count == null || stride == null ||
                        compressionMode == null || rawTargets == null) {
                        result.error("INVALID_ARGS", "Missing batch arguments", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        try {
                            val batch = NativeCrypto.searchBatch(
                                startKey,
                                count,
                                stride,
                                compressionMode,
                                rawTargets.toTypedArray()
                            )
                            runOnUiThread { result.success(batch) }
                        } catch (error: Throwable) {
                            runOnUiThread {
                                result.error("NATIVE_ERROR", error.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "background_search"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        val intent = Intent(this, BackgroundSearchService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error("SERVICE_START_FAILED", error.message, null)
                    }
                }
                "stop" -> {
                    try {
                        stopService(Intent(this, BackgroundSearchService::class.java))
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error("SERVICE_STOP_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
