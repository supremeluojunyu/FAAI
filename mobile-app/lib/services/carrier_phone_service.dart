import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CarrierPhoneResult {
  final String? phone;
  final String? operator;
  final String? error;

  const CarrierPhoneResult({this.phone, this.operator, this.error});

  bool get ok => phone != null && phone!.length == 11;
}

class CarrierPhoneService {
  static const _channel = MethodChannel('com.example.moyu_app/carrier');

  Future<bool> requestPermission() async {
    final statuses = await [
      Permission.phone,
      if (await Permission.phone.isRestricted) Permission.sms,
    ].request();
    return statuses[Permission.phone]?.isGranted ?? false;
  }

  Future<CarrierPhoneResult> fetchCarrierPhone() async {
    final granted = await requestPermission();
    if (!granted) {
      return const CarrierPhoneResult(error: 'permission_denied');
    }
    try {
      final raw = await _channel.invokeMethod<Map>('getCarrierPhone');
      final map = raw?.map((k, v) => MapEntry(k.toString(), v?.toString())) ?? {};
      return CarrierPhoneResult(
        phone: map['phone'],
        operator: map['operator'],
        error: map['error'],
      );
    } on PlatformException catch (e) {
      return CarrierPhoneResult(error: e.message ?? 'platform_error');
    }
  }

  static String maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
}
