import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key, required this.apiBaseUrl, required this.onLogout});
  final String apiBaseUrl;
  final VoidCallback onLogout;

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  String? _phone;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = AuthService(widget.apiBaseUrl);
    final phone = await auth.getGuestPhone();
    final isGuest = await auth.isGuest();
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _isGuest = isGuest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ['我的收藏', '浏览足迹', '草稿箱', '钱包', '设置', '客服帮助'];
    final displayName = _isGuest ? '游客' : '用户';
    final subtitle = _phone != null && _phone!.isNotEmpty ? _phone! : '这个人很懒，什么都没写';
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(child: Icon(_isGuest ? Icons.visibility_outlined : Icons.person)),
              title: Text(displayName),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((e) => Card(child: ListTile(title: Text(e), trailing: const Icon(Icons.chevron_right)))),
          Card(
            child: ListTile(
              title: const Text('退出登录'),
              trailing: const Icon(Icons.logout),
              onTap: () async {
                await AuthService(widget.apiBaseUrl).logout();
                widget.onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
