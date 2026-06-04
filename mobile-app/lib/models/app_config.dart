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

class AppConfig {
  final String apiBaseUrl;
  final String wsUrl;
  final bool maintenance;
  final Map<String, dynamic> features;
  final SplashAdsConfig splashAds;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.maintenance,
    required this.features,
    this.splashAds = const SplashAdsConfig(),
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      wsUrl: json['wsUrl'] as String? ?? '',
      maintenance: json['maintenance'] as bool? ?? false,
      features: (json['features'] as Map<String, dynamic>?) ?? {},
      splashAds: SplashAdsConfig.fromJson(json['splashAds'] as Map<String, dynamic>?),
    );
  }
}
