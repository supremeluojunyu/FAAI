import 'package:dio/dio.dart';
import '../models/app_config.dart';

class ConfigService {
  final Dio _dio = Dio();

  Future<AppConfig> fetchConfig() async {
    final resp = await _dio.get('https://config.yourdomain.com/app-config.json');
    return AppConfig.fromJson(resp.data as Map<String, dynamic>);
  }
}
