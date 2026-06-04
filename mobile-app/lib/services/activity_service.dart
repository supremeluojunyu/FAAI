import 'package:dio/dio.dart';
import 'api_dio.dart';
import 'auth_service.dart';

/// 将 App 内页面浏览、 Tab 切换等写入后台用户日志（需已登录）。
class ActivityService {
  ActivityService(this.baseUrl);
  final String baseUrl;

  Future<void> log(
    String action, {
    String? targetType,
    String? targetId,
    Map<String, dynamic>? detail,
  }) async {
    final token = await AuthService(baseUrl).getLocalToken();
    if (token == null || token.isEmpty) return;
    try {
      final dio = createApiDio(baseUrl, connectTimeout: const Duration(seconds: 8));
      await dio.post(
        '/user/activity',
        data: {
          'action': action,
          if (targetType != null) 'target_type': targetType,
          if (targetId != null) 'target_id': targetId,
          if (detail != null) 'detail': detail,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {
      // 日志失败不影响主流程
    }
  }

  void logTab(String tab) {
    log('OPEN_TAB', targetType: 'tab', targetId: tab, detail: {'tab': tab});
  }

  void logPage(String page, {Map<String, dynamic>? extra}) {
    log('OPEN_PAGE', targetType: 'page', targetId: page, detail: {'page': page, ...?extra});
  }
}
