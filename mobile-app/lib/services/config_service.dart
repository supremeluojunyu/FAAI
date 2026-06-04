import 'package:dio/dio.dart';
import '../config/bootstrap_config.dart';
import '../models/app_config.dart';
import 'config_storage.dart';

class ConfigService {
  static const maxAttemptsPerUrl = 3;
  static const retryDelay = Duration(seconds: 2);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<AppConfig> fetchConfig() async {
    final savedApi = await ConfigStorage.getSavedApiBaseUrl();
    final savedWs = await ConfigStorage.getSavedWsUrl();
    if (savedApi != null && savedApi.isNotEmpty) {
      return AppConfig(
        apiBaseUrl: savedApi,
        wsUrl: savedWs ?? '${savedApi.replaceFirst('/api/v1', '').replaceFirst('http', 'ws')}/ws',
        maintenance: false,
        features: const {},
        splashAds: const SplashAdsConfig(),
      );
    }

    Object? lastError;
    final urls = _uniqueUrls([
      ...BootstrapConfig.configUrls,
      '${BootstrapConfig.publicBaseUrl}/app-config.json',
    ]);

    for (final url in urls) {
      for (var i = 0; i < maxAttemptsPerUrl; i++) {
        try {
          final resp = await _dio.get(
            url,
            options: Options(responseType: ResponseType.json),
          );
          return AppConfig.fromJson(resp.data as Map<String, dynamic>);
        } catch (e) {
          lastError = e;
          if (i < maxAttemptsPerUrl - 1) {
            await Future.delayed(retryDelay);
          }
        }
      }
    }

    if (BootstrapConfig.publicBaseUrl.isNotEmpty) {
      throw Exception('无法连接服务器($lastError)，请手动配置');
    }
    throw Exception('无法加载远程配置: $lastError');
  }

  List<String> _uniqueUrls(List<String> urls) {
    final seen = <String>{};
    return urls.where((u) => u.isNotEmpty && seen.add(u)).toList();
  }
}
