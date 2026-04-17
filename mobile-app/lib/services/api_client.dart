import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiClient {
  final Dio dio;
  final AuthService _authService;
  ApiClient._(this.dio, this._authService);

  factory ApiClient(String baseUrl) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));
    return ApiClient._(dio, AuthService(baseUrl));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final token = await _authService.getLocalToken();
    final resp = await dio.get(path, queryParameters: query, options: _auth(token));
    return _unwrap(resp.data);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final token = await _authService.getLocalToken();
    final resp = await dio.post(path, data: data, options: _auth(token));
    return _unwrap(resp.data);
  }

  Options _auth(String? token) {
    return Options(headers: token == null || token.isEmpty ? {} : {"Authorization": "Bearer $token"});
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final body = (raw as Map).cast<String, dynamic>();
    final code = body["code"] as num? ?? 0;
    if (code != 0) {
      throw Exception((body["message"] ?? "请求失败").toString());
    }
    return (body["data"] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
