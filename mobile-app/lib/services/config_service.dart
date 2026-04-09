import 'package:dio/dio.dart';
import '../models/app_config.dart';

class ConfigService {
  final Dio _dio = Dio();

  Future<AppConfig> fetchConfig() async {
    final resp = await _dio.get(
      'http://192.168.3.13/app-config.json',
      options: Options(responseType: ResponseType.json),
    );
    return AppConfig.fromJson(resp.data as Map<String, dynamic>);
  }
}
