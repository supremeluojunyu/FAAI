import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/model_service.dart';
import '../../services/user_hub_service.dart';

class ModelDetailPage extends ConsumerStatefulWidget {
  const ModelDetailPage({super.key, required this.modelId});
  final String modelId;

  @override
  ConsumerState<ModelDetailPage> createState() => _ModelDetailPageState();
}

class _ModelDetailPageState extends ConsumerState<ModelDetailPage> {
  ModelDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await ref.read(appConfigProvider.future);
      final detail = await ModelService(cfg.apiBaseUrl).getModel(widget.modelId);
      await UserHubService(cfg.apiBaseUrl).addBrowseHistory(detail.item);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? '加载失败')),
      );
    }
    final d = _detail!;
    final sizeMb = (d.fileSize / 1024 / 1024).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: Text(d.item.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('购买功能即将上线，请先收藏')));
            },
            child: Text('立即购买 ¥${d.item.price}'),
          ),
        ),
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              d.item.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF334155)),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('¥${d.item.price}', style: const TextStyle(color: Color(0xFFF97316), fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('格式 ${d.format} | 大小 ${sizeMb}MB | ${d.item.category}'),
                  if (d.designer?['nickname'] != null) ...[
                    const SizedBox(height: 8),
                    Text('设计师：${d.designer!['nickname']}'),
                  ],
                  const SizedBox(height: 12),
                  Text(d.description.isEmpty ? '暂无描述' : d.description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
