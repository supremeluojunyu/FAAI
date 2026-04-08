class AppConfig {
  final String apiBaseUrl;
  final String wsUrl;
  final bool maintenance;
  final Map<String, dynamic> features;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.maintenance,
    required this.features,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      wsUrl: json['wsUrl'] as String? ?? '',
      maintenance: json['maintenance'] as bool? ?? false,
      features: (json['features'] as Map<String, dynamic>?) ?? {},
    );
  }
}
