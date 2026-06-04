import '../utils/version_compare.dart';

class VersionPolicy {
  final bool enabled;
  final String minVersion;
  final int minBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final List<String> blockedVersions;
  final bool forceUpdate;
  final String title;
  final String message;
  final String downloadPageUrl;
  final String downloadApkUrl;

  const VersionPolicy({
    this.enabled = false,
    this.minVersion = '0.0.0',
    this.minBuildNumber = 0,
    this.latestVersion = '',
    this.latestBuildNumber = 0,
    this.blockedVersions = const [],
    this.forceUpdate = true,
    this.title = '需要更新',
    this.message = '请下载安装最新版本后继续使用',
    this.downloadPageUrl = '',
    this.downloadApkUrl = '',
  });

  factory VersionPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VersionPolicy();
    final blocked = (json['blockedVersions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return VersionPolicy(
      enabled: json['enabled'] as bool? ?? false,
      minVersion: (json['minVersion'] ?? '0.0.0').toString(),
      minBuildNumber: (json['minBuildNumber'] as num?)?.toInt() ?? 0,
      latestVersion: (json['latestVersion'] ?? '').toString(),
      latestBuildNumber: (json['latestBuildNumber'] as num?)?.toInt() ?? 0,
      blockedVersions: blocked,
      forceUpdate: json['forceUpdate'] as bool? ?? true,
      title: (json['title'] ?? '需要更新').toString(),
      message: (json['message'] ?? '').toString(),
      downloadPageUrl: (json['downloadPageUrl'] ?? '').toString(),
      downloadApkUrl: (json['downloadApkUrl'] ?? '').toString(),
    );
  }

  String resolveDownloadUrl({String? fallbackPage, String? fallbackApk}) {
    if (downloadApkUrl.isNotEmpty) return downloadApkUrl;
    if (downloadPageUrl.isNotEmpty) return downloadPageUrl;
    if (fallbackApk != null && fallbackApk.isNotEmpty) return fallbackApk;
    return fallbackPage ?? '';
  }

  bool isAllowed({required String version, required int buildNumber}) {
    if (!enabled) return true;
    for (final b in blockedVersions) {
      if (VersionCompare.equals(version, b)) return false;
    }
    if (minVersion.isNotEmpty && VersionCompare.compare(version, minVersion) < 0) {
      return false;
    }
    if (minBuildNumber > 0 && buildNumber > 0 && buildNumber < minBuildNumber) {
      return false;
    }
    return true;
  }
}
