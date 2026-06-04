import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/model_service.dart';
import '../../services/user_hub_service.dart';
import '../../utils/share_helper.dart';

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
  bool _actionBusy = false;

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
      final svc = ModelService(cfg.apiBaseUrl);
      final detail = await svc.getModel(widget.modelId);
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

  Future<bool> _ensureLoggedIn() async {
    final cfg = await ref.read(appConfigProvider.future);
    final token = await AuthService(cfg.apiBaseUrl).getLocalToken();
    if (token != null && token.isNotEmpty) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录后再操作')));
    return false;
  }

  Future<void> _toggleFavorite() async {
    if (!await _ensureLoggedIn()) return;
    setState(() => _actionBusy = true);
    try {
      final cfg = await ref.read(appConfigProvider.future);
      final favorited = await ModelService(cfg.apiBaseUrl).toggleFavorite(widget.modelId);
      if (!mounted || _detail == null) return;
      setState(() {
        _detail = ModelDetail(
          item: _detail!.item,
          description: _detail!.description,
          format: _detail!.format,
          fileSize: _detail!.fileSize,
          designer: _detail!.designer,
          isFavorited: favorited,
          isLiked: _detail!.isLiked,
          favoriteCount: _detail!.favoriteCount + (favorited ? 1 : -1),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(favorited ? '已收藏' : '已取消收藏')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _toggleLike() async {
    if (!await _ensureLoggedIn()) return;
    setState(() => _actionBusy = true);
    try {
      final cfg = await ref.read(appConfigProvider.future);
      final r = await ModelService(cfg.apiBaseUrl).toggleLike(widget.modelId);
      if (!mounted || _detail == null) return;
      setState(() {
        _detail = ModelDetail(
          item: ModelItem(
            id: _detail!.item.id,
            title: _detail!.item.title,
            coverUrl: _detail!.item.coverUrl,
            category: _detail!.item.category,
            price: _detail!.item.price,
            likeCount: r.count,
          ),
          description: _detail!.description,
          format: _detail!.format,
          fileSize: _detail!.fileSize,
          designer: _detail!.designer,
          isFavorited: _detail!.isFavorited,
          isLiked: r.liked,
          favoriteCount: _detail!.favoriteCount,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _share() async {
    if (!await _ensureLoggedIn()) return;
    final d = _detail;
    if (d == null) return;
    try {
      final cfg = await ref.read(appConfigProvider.future);
      await ModelService(cfg.apiBaseUrl).shareModel(widget.modelId);
      final link = '${cfg.apiBaseUrl.replaceAll('/api/v1', '')}/download/';
      await ShareHelper.shareText(
        title: d.item.title,
        text: '模宇宙(糖艺大模王) - ${d.item.title} ¥${d.item.price}',
        link: link,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
      appBar: AppBar(
        title: Text(d.item.title),
        actions: [
          IconButton(
            onPressed: _actionBusy ? null : _share,
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _actionBusy ? null : _toggleFavorite,
                icon: Icon(d.isFavorited ? Icons.favorite : Icons.favorite_border, color: d.isFavorited ? Colors.red : null),
                tooltip: '收藏',
              ),
              IconButton(
                onPressed: _actionBusy ? null : _toggleLike,
                icon: Icon(d.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: d.isLiked ? Colors.blue : null),
                tooltip: '点赞',
              ),
              Text('${d.item.likeCount}', style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('购买功能即将上线')));
                  },
                  child: Text('立即购买 ¥${d.item.price}'),
                ),
              ),
            ],
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
                  Text('格式 ${d.format} | 大小 ${sizeMb}MB | ${d.item.category} · 收藏 ${d.favoriteCount}'),
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
