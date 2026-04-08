import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ref.read(configServiceProvider).fetchConfig();
});
