import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CarrierPhoneResult {
  final String? phone;
  final String? operator;
  final String? deviceId;
  final String? error;
  final bool simReady;

  const CarrierPhoneResult({
    this.phone,
    this.operator,
    this.deviceId,
    this.error,
    this.simReady = false,
  });

  static final _mobileRe = RegExp(r'^1[3-9]\d{9}$');

  bool get hasRealPhone => phone != null && _mobileRe.hasMatch(phone!);

  /// SIM 未返回号码时，仍可用设备标识 + 运营商信息完成认证
  bool get canAuth => hasRealPhone || (deviceId != null && deviceId!.isNotEmpty);
}

class CarrierPhoneService {
  static const _channel = MethodChannel('com.example.moyu_app/carrier');

  Future<bool> requestPermission() async {
    var phoneStatus = await Permission.phone.status;
    if (phoneStatus.isDenied || phoneStatus.isLimited) {
      phoneStatus = await Permission.phone.request();
    }
    if (phoneStatus.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return phoneStatus.isGranted;
  }

  Future<CarrierPhoneResult> fetchCarrierPhone() async {
    await requestPermission();
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getCarrierPhone');
      final map = raw?.map((k, v) => MapEntry(k.toString(), v?.toString())) ?? {};
      return CarrierPhoneResult(
        phone: map['phone'],
        operator: map['operator'],
        deviceId: map['deviceId'],
        error: map['error'],
        simReady: map['simReady'] == 'true',
      );
    } on PlatformException catch (e) {
      return CarrierPhoneResult(error: e.message ?? 'platform_error');
    }
  }

  static bool isRealMobile(String? phone) =>
      phone != null && _mobileRe.hasMatch(phone);

  static String maskPhone(String phone) {
    if (!isRealMobile(phone)) return '本机认证账号';
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
}
