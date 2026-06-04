import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_config.dart';
import 'pages/ad_splash_page.dart';
import 'pages/community/community_page.dart';
import 'pages/config_gate.dart';
import 'pages/demand_publish/demand_publish_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/mine/mine_page.dart';
import 'pages/workbench/workbench_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '模宇宙(糖艺大模王)',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: ConfigGate(childBuilder: (config) => AppGate(config: config)),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.config});
  final AppConfig config;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _canEnter = false;
  bool _loading = true;
  bool _adsFinished = false;

  String get _apiBaseUrl => widget.config.apiBaseUrl;

  bool get _shouldShowAds => widget.config.splashAds.shouldShow && !_adsFinished;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = AuthService(_apiBaseUrl);
    _canEnter = await auth.canEnter();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_shouldShowAds) {
      return AdSplashPage(
        config: widget.config.splashAds,
        onFinished: () => setState(() => _adsFinished = true),
      );
    }

    if (!_canEnter) {
      return LoginPage(
        authService: AuthService(_apiBaseUrl),
        onLoginSuccess: () => setState(() => _canEnter = true),
      );
    }

    return MainShell(
      apiBaseUrl: _apiBaseUrl,
      onLogout: () => setState(() => _canEnter = false),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.apiBaseUrl, required this.onLogout});
  final String apiBaseUrl;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int current = 0;
  List<Widget> get pages => [
        const HomePage(),
        const DemandPublishPage(),
        WorkbenchPage(apiBaseUrl: widget.apiBaseUrl),
        const CommunityPage(),
        MinePage(apiBaseUrl: widget.apiBaseUrl, onLogout: widget.onLogout),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[current],
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (v) => setState(() => current = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: '商城'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'AI&接单'),
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), label: '工作台'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: '社区'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
