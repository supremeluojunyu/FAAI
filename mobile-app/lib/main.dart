import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/community/community_page.dart';
import 'pages/demand_publish/demand_publish_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/mine/mine_page.dart';
import 'pages/workbench/workbench_page.dart';
import 'providers/app_providers.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    return MaterialApp(
      title: '模宇宙',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: cfg.when(
        data: (config) => AppGate(apiBaseUrl: config.apiBaseUrl),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(body: Center(child: Text('配置加载失败'))),
      ),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = AuthService(widget.apiBaseUrl);
    _token = await auth.getLocalToken();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_token == null || _token!.isEmpty) {
      return LoginPage(
        authService: AuthService(widget.apiBaseUrl),
        onLoginSuccess: () => setState(() => _token = 'ok'),
      );
    }
    return MainShell(
      apiBaseUrl: widget.apiBaseUrl,
      onLogout: () => setState(() => _token = null),
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
