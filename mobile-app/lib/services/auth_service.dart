import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/version_policy.dart';
import '../pages/force_update_page.dart';
import 'api_dio.dart';

class AuthService {
  AuthService(this.baseUrl);
  final String baseUrl;

  static const _tokenKey = 'auth_token';
  static const _guestPhoneKey = 'guest_phone';
  static const _isGuestKey = 'is_guest';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Dio _dio() => createApiDio(baseUrl);

  void _throwIfForceUpdate(dynamic data) {
    final payload = parseForceUpdatePayload(data);
    if (payload == null) return;
    final policy = VersionPolicy(
      enabled: true,
      forceUpdate: payload['force_update'] != false,
      title: (payload['title'] ?? '需要更新').toString(),
      message: (payload['message'] ?? '请更新 App').toString(),
      downloadPageUrl: (payload['download_page_url'] ?? '').toString(),
      downloadApkUrl: (payload['download_apk_url'] ?? '').toString(),
      minVersion: (payload['min_version'] ?? '').toString(),
      minBuildNumber: (payload['min_build_number'] as num?)?.toInt() ?? 0,
      latestVersion: (payload['latest_version'] ?? '').toString(),
    );
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForceUpdatePage(
          policy: policy,
          reason: (payload['reason'] ?? policy.message).toString(),
          downloadUrl: policy.resolveDownloadUrl(),
        ),
      ),
      (_) => false,
    );
    throw Exception(policy.message);
  }

  void _checkResponse(dynamic raw) {
    if (raw is Map) _throwIfForceUpdate(raw);
  }

  Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getGuestPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestPhoneKey);
  }

  Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  Future<bool> canEnter() async {
    final token = await getLocalToken();
    if (token != null && token.isNotEmpty) return true;
    final phone = await getGuestPhone();
    return phone != null && phone.isNotEmpty;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveGuestPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestPhoneKey, phone);
    await prefs.setBool(_isGuestKey, true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_guestPhoneKey);
    await prefs.remove(_isGuestKey);
  }

  Future<String> sendCode(String phone) async {
    final resp = await _dio().post('/auth/send-code', data: {'phone': phone});
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    return (data['debug_code'] ?? '').toString();
  }

  Future<void> loginBySms({required String phone, required String code}) async {
    final resp = await _dio().post('/auth/login', data: {'phone': phone, 'code': code});
    _checkResponse(resp.data);
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('登录失败：token为空');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    await prefs.setString(_guestPhoneKey, phone);
    await saveToken(token);
  }

  Future<void> loginByCarrier({String? phone, String? operator, String? deviceId}) async {
    final resp = await _dio().post('/auth/carrier-login', data: {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (operator != null) 'operator': operator,
      if (deviceId != null) 'deviceId': deviceId,
    });
    _checkResponse(resp.data);
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('一键登录失败：token为空');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    final savedPhone = ((data['user'] as Map?)?['phone'] ?? phone ?? '').toString();
    await prefs.setString(_guestPhoneKey, savedPhone);
    await saveToken(token);
  }

  Future<void> loginAsGuest({String? phone, String? deviceId, String? operator}) async {
    final resp = await _dio().post('/auth/guest', data: {
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (deviceId != null) 'deviceId': deviceId,
      if (operator != null) 'operator': operator,
    });
    _checkResponse(resp.data);
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('游客进入失败：token为空');
    final savedPhone = ((data['user'] as Map?)?['phone'] ?? phone ?? '').toString();
    await saveToken(token);
    await saveGuestPhone(savedPhone);
  }

  Future<void> loginByWechatCode(String wechatCode) async {
    final resp = await _dio().post('/auth/wechat/login', data: {'code': wechatCode});
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('微信登录失败：token为空');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, false);
    await saveToken(token);
  }
}
