import 'package:dio/dio.dart';
import '../utils/app_version_info.dart';

/// 统一 API 客户端：附带 App 版本头，供服务端版本校验。
Dio createApiDio(String baseUrl, {Duration? connectTimeout}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout ?? const Duration(seconds: 10),
    headers: const {'X-App-Client': 'moyu-app'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final info = await AppVersionInfo.get();
      options.headers['X-App-Version'] = info.version;
      options.headers['X-App-Build'] = info.buildNumber.toString();
      handler.next(options);
    },
  ));

  return dio;
}

int? parseForceUpdateCode(dynamic data) {
  if (data is! Map) return null;
  final code = data['code'];
  if (code is num && code.toInt() == 1009) return 1009;
  return null;
}

Map<String, dynamic>? parseForceUpdatePayload(dynamic data) {
  if (data is! Map || parseForceUpdateCode(data) != 1009) return null;
  final payload = data['data'];
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}
