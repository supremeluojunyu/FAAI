import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService(this.baseUrl);
  final String baseUrl;

  static const _tokenKey = 'auth_token';

  Dio _dio() => Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String> sendCode(String phone) async {
    final resp = await _dio().post('/auth/send-code', data: {'phone': phone});
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    // 开发环境后端会回 debug_code，便于真机联调。
    return (data['debug_code'] ?? '').toString();
  }

  Future<void> loginBySms({required String phone, required String code}) async {
    final resp = await _dio().post('/auth/login', data: {'phone': phone, 'code': code});
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('登录失败：token为空');
    await saveToken(token);
  }

  Future<void> loginByWechatCode(String wechatCode) async {
    final resp = await _dio().post('/auth/wechat/login', data: {'code': wechatCode});
    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('微信登录失败：token为空');
    await saveToken(token);
  }
}
