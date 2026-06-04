package com.example.moyu_app

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.moyu_app/carrier"
    private val reqPhone = 9101
    private var pendingCarrierResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCarrierPhone" -> requestCarrierPhone(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCarrierPhone(result: MethodChannel.Result) {
        if (hasPhonePermission(this)) {
            result.success(readCarrierInfo(this))
            return
        }
        pendingCarrierResult = result
        val perms = mutableListOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_PHONE_NUMBERS
        )
        ActivityCompat.requestPermissions(this, perms.toTypedArray(), reqPhone)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != reqPhone) return
        val pending = pendingCarrierResult ?: return
        pendingCarrierResult = null
        pending.success(readCarrierInfo(this))
    }

    @SuppressLint("MissingPermission", "HardwareIds")
    private fun readCarrierInfo(context: Context): Map<String, String?> {
        val deviceId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        val hasPerm = hasPhonePermission(context)
        if (!hasPerm) {
            return mapOf(
                "phone" to null,
                "operator" to null,
                "deviceId" to deviceId,
                "simReady" to "false",
                "error" to "permission_denied"
            )
        }

        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val candidates = mutableListOf<String?>()
        candidates.add(tm.line1Number)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val sm = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val subs = sm.activeSubscriptionInfoList
            if (!subs.isNullOrEmpty()) {
                for (info in subs) {
                    candidates.add(info.number)
                    if (Build.VERSION.SDK_INT >= 33) {
                        try {
                            candidates.add(sm.getPhoneNumber(info.subscriptionId))
                        } catch (_: Exception) {
                        }
                    }
                }
            }
        }

        var phone: String? = null
        for (raw in candidates) {
            phone = normalizePhone(raw)
            if (phone != null) break
        }

        val operator = normalizeOperatorName(tm.simOperatorName) ?: detectOperator(phone) ?: "运营商"
        val simReady = if (tm.simState == TelephonyManager.SIM_STATE_READY) "true" else "false"

        return mapOf(
            "phone" to phone,
            "operator" to operator,
            "deviceId" to deviceId,
            "simReady" to simReady,
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

    private fun normalizeOperatorName(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        val name = raw.trim()
        val u = name.uppercase()
        return when {
            u.contains("CMCC") || u.contains("MOBILE") || name.contains("移动") -> "中国移动"
            u.contains("UNICOM") || u.contains("CUCC") || name.contains("联通") -> "中国联通"
            u.contains("TELECOM") || u.contains("CTCC") || name.contains("电信") -> "中国电信"
            else -> name
        }
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
