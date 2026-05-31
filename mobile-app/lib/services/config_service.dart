import 'package:dio/dio.dart';
import '../config/bootstrap_config.dart';
import '../models/app_config.dart';

class ConfigService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<AppConfig> fetchConfig() async {
    Object? lastError;
    for (final url in BootstrapConfig.configUrls) {
      try {
        final resp = await _dio.get(
          url,
          options: Options(responseType: ResponseType.json),
        );
        return AppConfig.fromJson(resp.data as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('无法加载远程配置: $lastError');
  }
}
