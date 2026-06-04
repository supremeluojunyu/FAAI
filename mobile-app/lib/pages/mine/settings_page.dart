import 'package:flutter/material.dart';
import '../../services/user_hub_service.dart';
import '../../services/config_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notify = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('消息通知'),
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
          ),
          ListTile(
            title: const Text('清除本地缓存'),
            subtitle: const Text('浏览足迹等本地数据'),
            onTap: () async {
              await UserHubService(widget.apiBaseUrl).clearLocalCache();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除本地缓存')));
            },
          ),
          ListTile(
            title: const Text('重置服务器配置'),
            subtitle: const Text('恢复自动拉取远程配置'),
            onTap: () async {
              await ConfigStorage.clearManualConfig();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已重置，请重启 App')));
            },
          ),
          const ListTile(
            title: Text('当前版本'),
            subtitle: Text('v0.0.5'),
          ),
        ],
      ),
    );
  }
}
