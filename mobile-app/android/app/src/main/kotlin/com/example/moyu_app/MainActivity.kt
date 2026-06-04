package com.example.moyu_app

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.moyu_app/carrier"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCarrierPhone" -> {
                    try {
                        val data = readCarrierPhone(applicationContext)
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("CARRIER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("MissingPermission", "HardwareIds")
    private fun readCarrierPhone(context: Context): Map<String, String?> {
        if (!hasPhonePermission(context)) {
            return mapOf("phone" to null, "operator" to null, "error" to "permission_denied")
        }

        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        var raw = tm.line1Number
        if (raw.isNullOrBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val sm = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val subs = sm.activeSubscriptionInfoList
            if (!subs.isNullOrEmpty()) {
                raw = subs[0].number
            }
        }

        val phone = normalizePhone(raw)
        val operator = when (tm.simOperatorName?.trim()) {
            "", null -> detectOperator(phone)
            else -> tm.simOperatorName
        }

        return mapOf(
            "phone" to phone,
            "operator" to operator,
            "error" to if (phone == null) "number_unavailable" else null
        )
    }

    private fun hasPhonePermission(context: Context): Boolean {
        val p1 = ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        val p2 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED
        } else true
        return p1 && p2
    }

    private fun normalizePhone(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        val digits = raw.replace(Regex("[^0-9]"), "")
        val phone = when {
            digits.length == 11 && digits.startsWith("1") -> digits
            digits.length == 13 && digits.startsWith("86") -> digits.substring(2)
            digits.length > 11 -> digits.takeLast(11)
            else -> null
        }
        return if (phone != null && phone.startsWith("1")) phone else null
    }

    private fun detectOperator(phone: String?): String? {
        if (phone == null || phone.length < 3) return null
        val prefix = phone.substring(0, 3)
        val cm = setOf("134", "135", "136", "137", "138", "139", "147", "150", "151", "152", "157", "158", "159", "172", "178", "182", "183", "184", "187", "188", "195", "197", "198")
        val cu = setOf("130", "131", "132", "145", "155", "156", "166", "171", "175", "176", "185", "186", "196")
        val ct = setOf("133", "149", "153", "173", "177", "180", "181", "189", "191", "193", "199")
        return when (prefix) {
            in cm -> "中国移动"
            in cu -> "中国联通"
            in ct -> "中国电信"
            else -> "运营商"
        }
    }
}
