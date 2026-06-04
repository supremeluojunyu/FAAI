import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final int buildNumber;

  static AppVersionInfo? _cache;

  static Future<AppVersionInfo> get() async {
    if (_cache != null) return _cache!;
    final info = await PackageInfo.fromPlatform();
    _cache = AppVersionInfo(
      version: info.version,
      buildNumber: int.tryParse(info.buildNumber) ?? 0,
    );
    return _cache!;
  }
}
