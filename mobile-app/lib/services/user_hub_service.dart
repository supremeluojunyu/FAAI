import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'model_service.dart';

class UserHubService {
  UserHubService(this.baseUrl);
  final String baseUrl;

  static const _historyKey = 'browse_history_v1';

  Dio _authDio() {
    final dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));
    return dio;
  }

  Future<String?> _token() => AuthService(baseUrl).getLocalToken();

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await _token();
    if (token == null || token.isEmpty) throw Exception('请先登录');
    final resp = await _authDio().get(path, options: Options(headers: {'Authorization': 'Bearer $token'}));
    final body = (resp.data as Map).cast<String, dynamic>();
    if ((body['code'] as num? ?? 0) != 0) throw Exception((body['message'] ?? '请求失败').toString());
    return (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<List<ModelItem>> fetchFavorites() async {
    final data = await _get('/user/favorites');
    final list = (data['list'] as List<dynamic>? ?? []).whereType<Map>().map((e) => ModelItem.fromJson(e.cast<String, dynamic>())).toList();
    return list;
  }

  Future<Map<String, dynamic>> fetchWallet() async {
    return _get('/wallet/balance');
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final data = await _get('/user/profile');
    return (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<void> updateProfile({String? nickname, String? bio}) async {
    final token = await _token();
    await _authDio().put(
      '/user/profile',
      data: {if (nickname != null) 'nickname': nickname, if (bio != null) 'bio': bio},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<Map<String, dynamic>>> fetchWorkbenchJobs() async {
    final data = await _get('/workbench/jobs');
    return (data['list'] as List<dynamic>? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> loadBrowseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<void> addBrowseHistory(ModelItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadBrowseHistory();
    list.removeWhere((e) => e['id'] == item.id);
    list.insert(0, {
      'id': item.id,
      'title': item.title,
      'coverUrl': item.coverUrl,
      'price': item.price,
      'viewedAt': DateTime.now().toIso8601String(),
    });
    final trimmed = list.take(50).toList();
    await prefs.setString(_historyKey, jsonEncode(trimmed));
  }

  Future<void> clearBrowseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> clearLocalCache() async {
    await clearBrowseHistory();
  }
}
