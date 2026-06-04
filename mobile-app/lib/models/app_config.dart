class SplashAdItem {
  final String id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final String network;

  const SplashAdItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    this.network = 'custom',
  });

  factory SplashAdItem.fromJson(Map<String, dynamic> json) {
    return SplashAdItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      linkUrl: (json['linkUrl'] ?? '').toString(),
      network: (json['network'] ?? 'custom').toString(),
    );
  }
}

class SplashAdsConfig {
  final bool enabled;
  final int skipAfterSec;
  final int durationSec;
  final List<SplashAdItem> items;

  const SplashAdsConfig({
    this.enabled = false,
    this.skipAfterSec = 2,
    this.durationSec = 5,
    this.items = const [],
  });

  factory SplashAdsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SplashAdsConfig();
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SplashAdsConfig(
      enabled: json['enabled'] as bool? ?? false,
      skipAfterSec: (json['skipAfterSec'] as num?)?.toInt() ?? 2,
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 5,
      items: rawItems
          .whereType<Map>()
          .map((e) => SplashAdItem.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.imageUrl.isNotEmpty)
          .toList(),
    );
  }

  bool get shouldShow => enabled && items.isNotEmpty;
}

class RechargePackage {
  final String id;
  final double amount;
  final double bonus;
  final String label;

  const RechargePackage({
    required this.id,
    required this.amount,
    required this.bonus,
    required this.label,
  });

  factory RechargePackage.fromJson(Map<String, dynamic> json) {
    return RechargePackage(
      id: (json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      label: (json['label'] ?? '').toString(),
    );
  }
}

class RechargePackagesConfig {
  final bool enabled;
  final String notice;
  final List<RechargePackage> packages;

  const RechargePackagesConfig({
    this.enabled = false,
    this.notice = '',
    this.packages = const [],
  });

  factory RechargePackagesConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RechargePackagesConfig();
    final raw = json['packages'] as List<dynamic>? ?? [];
    return RechargePackagesConfig(
      enabled: json['enabled'] as bool? ?? false,
      notice: (json['notice'] ?? '').toString(),
      packages: raw
          .whereType<Map>()
          .map((e) => RechargePackage.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class WalletConfig {
  final bool rechargeEnabled;
  final bool withdrawEnabled;
  final double withdrawMin;
  final String withdrawTip;
  final String balanceTip;

  const WalletConfig({
    this.rechargeEnabled = true,
    this.withdrawEnabled = false,
    this.withdrawMin = 10,
    this.withdrawTip = '',
    this.balanceTip = '',
  });

  factory WalletConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WalletConfig();
    return WalletConfig(
      rechargeEnabled: json['rechargeEnabled'] as bool? ?? true,
      withdrawEnabled: json['withdrawEnabled'] as bool? ?? false,
      withdrawMin: (json['withdrawMin'] as num?)?.toDouble() ?? 10,
      withdrawTip: (json['withdrawTip'] ?? '').toString(),
      balanceTip: (json['balanceTip'] ?? '').toString(),
    );
  }
}

import 'version_policy.dart';

class AppConfig {
  final String apiBaseUrl;
  final String wsUrl;
  final bool maintenance;
  final Map<String, dynamic> features;
  final SplashAdsConfig splashAds;
  final RechargePackagesConfig rechargePackages;
  final WalletConfig walletConfig;
  final VersionPolicy versionPolicy;
  final String apkDownloadUrl;
  final String apkPageUrl;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.maintenance,
    required this.features,
    this.splashAds = const SplashAdsConfig(),
    this.rechargePackages = const RechargePackagesConfig(),
    this.walletConfig = const WalletConfig(),
    this.versionPolicy = const VersionPolicy(),
    this.apkDownloadUrl = '',
    this.apkPageUrl = '',
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      wsUrl: json['wsUrl'] as String? ?? '',
      maintenance: json['maintenance'] as bool? ?? false,
      features: (json['features'] as Map<String, dynamic>?) ?? {},
      splashAds: SplashAdsConfig.fromJson(json['splashAds'] as Map<String, dynamic>?),
      rechargePackages: RechargePackagesConfig.fromJson(json['rechargePackages'] as Map<String, dynamic>?),
      walletConfig: WalletConfig.fromJson(json['walletConfig'] as Map<String, dynamic>?),
      versionPolicy: VersionPolicy.fromJson(json['versionPolicy'] as Map<String, dynamic>?),
      apkDownloadUrl: (json['apkDownloadUrl'] ?? '').toString(),
      apkPageUrl: (json['apkPageUrl'] ?? '').toString(),
    );
  }
}
