import 'package:flutter/material.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/carrier_phone_service.dart';
import '../../services/user_hub_service.dart';
import 'drafts_page.dart';
import 'favorites_page.dart';
import 'help_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'wallet_page.dart';

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
  String _nickname = '用户';

  @override
  void initState() {
    super.initState();
    ActivityService(widget.apiBaseUrl).logPage('mine');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = AuthService(widget.apiBaseUrl);
    final phone = await auth.getGuestPhone();
    final isGuest = await auth.isGuest();
    var nickname = isGuest ? '游客' : '用户';
    if (!isGuest) {
      try {
        final profile = await UserHubService(widget.apiBaseUrl).fetchProfile();
        nickname = (profile['nickname'] ?? nickname).toString();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _isGuest = isGuest;
      _nickname = nickname;
    });
  }

  void _open(Widget page, String pageName) {
    ActivityService(widget.apiBaseUrl).logPage(pageName);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _editProfile() async {
    final ctrl = TextEditingController(text: _nickname);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑昵称'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '昵称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserHubService(widget.apiBaseUrl).updateProfile(nickname: ctrl.text.trim());
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = CarrierPhoneService.isRealMobile(_phone)
        ? CarrierPhoneService.maskPhone(_phone!)
        : '未绑定真实手机号（可退出后用短信登录）';

    final menus = <(String, IconData, VoidCallback)>[
      ('我的收藏', Icons.favorite_border, () => _open(FavoritesPage(apiBaseUrl: widget.apiBaseUrl), 'favorites')),
      ('浏览足迹', Icons.history, () => _open(HistoryPage(apiBaseUrl: widget.apiBaseUrl), 'history')),
      ('草稿箱', Icons.drafts_outlined, () => _open(DraftsPage(apiBaseUrl: widget.apiBaseUrl), 'drafts')),
      ('钱包', Icons.account_balance_wallet_outlined, () => _open(WalletPage(apiBaseUrl: widget.apiBaseUrl), 'wallet')),
      ('设置', Icons.settings_outlined, () => _open(SettingsPage(apiBaseUrl: widget.apiBaseUrl), 'settings')),
      ('客服帮助', Icons.help_outline, () => _open(const HelpPage(), 'help')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(child: Icon(_isGuest ? Icons.visibility_outlined : Icons.person)),
              title: Text(_nickname),
              subtitle: Text(subtitle),
              trailing: IconButton(icon: const Icon(Icons.edit), onPressed: _isGuest ? null : _editProfile),
            ),
          ),
          const SizedBox(height: 8),
          ...menus.map(
            (m) => Card(
              child: ListTile(
                leading: Icon(m.$2),
                title: Text(m.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: m.$3,
              ),
            ),
          ),
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
