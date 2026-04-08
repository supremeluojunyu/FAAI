import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/community/community_page.dart';
import 'pages/demand_publish/demand_publish_page.dart';
import 'pages/home_page.dart';
import 'pages/mine/mine_page.dart';
import 'pages/workbench/workbench_page.dart';
import 'providers/app_providers.dart';
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
        data: (_) => const MainShell(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(body: Center(child: Text('配置加载失败'))),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int current = 0;
  final pages = const [HomePage(), DemandPublishPage(), WorkbenchPage(), CommunityPage(), MinePage()];

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
