import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/bootstrap_config.dart';
import '../models/app_config.dart';
import '../providers/app_providers.dart';
import '../services/config_storage.dart';

class ManualConfigPage extends StatefulWidget {
  const ManualConfigPage({
    super.key,
    required this.initialBaseUrl,
    required this.onConfigured,
  });

  final String initialBaseUrl;
  final VoidCallback onConfigured;

  @override
  State<ManualConfigPage> createState() => _ManualConfigPageState();
}

class _ManualConfigPageState extends State<ManualConfigPage> {
  late final _baseCtrl = TextEditingController(text: widget.initialBaseUrl);
  bool _saving = false;
  String? _error;

  String _normalizeBase(String input) {
    var v = input.trim();
    if (v.endsWith('/')) v = v.substring(0, v.length - 1);
    if (v.endsWith('/api/v1')) v = v.substring(0, v.length - '/api/v1'.length);
    return v;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final base = _normalizeBase(_baseCtrl.text);
      if (!base.startsWith('http://') && !base.startsWith('https://')) {
        throw Exception('请以 http:// 或 https:// 开头');
      }
      final apiBase = '$base/api/v1';
      final wsBase = base.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      await ConfigStorage.saveManualConfig(apiBaseUrl: apiBase, wsUrl: '$wsBase/ws');
      if (!mounted) return;
      widget.onConfigured();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retryAuto() async {
    await ConfigStorage.clearManualConfig();
    if (!mounted) return;
    widget.onConfigured();
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配置服务器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('自动加载配置未成功，请确认服务器地址。默认已填入 FRP 公网地址。'),
          const SizedBox(height: 16),
          TextField(
            controller: _baseCtrl,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: 'http://124.220.4.69:8081',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          const Text('示例：http://公网IP:端口  或  http://192.168.x.x', style: TextStyle(color: Colors.grey)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存并连接'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : _retryAuto,
            child: const Text('重新自动加载'),
          ),
        ],
      ),
    );
  }
}

class ConfigGate extends ConsumerWidget {
  const ConfigGate({super.key, required this.childBuilder});

  final Widget Function(AppConfig config) childBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    return cfg.when(
      data: (config) => childBuilder(config),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => ManualConfigPage(
        initialBaseUrl: BootstrapConfig.publicBaseUrl,
        onConfigured: () => ref.invalidate(appConfigProvider),
      ),
    );
  }
}
