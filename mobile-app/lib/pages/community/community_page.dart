import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../utils/share_helper.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  List<CommunityPost> _posts = [];
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
      final list = await PostService(cfg.apiBaseUrl).listPosts();
      if (!mounted) return;
      setState(() {
        _posts = list;
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

  Future<void> _toggleLike(int index) async {
    if (!await _ensureLoggedIn()) return;
    final post = _posts[index];
    try {
      final cfg = await ref.read(appConfigProvider.future);
      final r = await PostService(cfg.apiBaseUrl).toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        _posts[index] = CommunityPost(
          id: post.id,
          content: post.content,
          likeCount: r.count,
          commentCount: post.commentCount,
          createdAt: post.createdAt,
          authorName: post.authorName,
          isLiked: r.liked,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _share(int index) async {
    if (!await _ensureLoggedIn()) return;
    final post = _posts[index];
    try {
      final cfg = await ref.read(appConfigProvider.future);
      await PostService(cfg.apiBaseUrl).sharePost(post.id);
      await ShareHelper.shareText(
        title: '模宇宙社区',
        text: '${post.authorName}：${post.content}',
        link: cfg.apiBaseUrl.replaceAll('/api/v1', ''),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    return '${diff.inMinutes.clamp(1, 59)}分钟前';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社区'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? const Center(child: Text('暂无社区动态'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (_, i) {
                          final p = _posts[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${p.authorName} · ${_timeAgo(p.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text(p.content, maxLines: 5, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleLike(i),
                                        child: Row(
                                          children: [
                                            Icon(p.isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: p.isLiked ? Colors.red : null),
                                            const SizedBox(width: 4),
                                            Text('${p.likeCount}'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Row(
                                        children: [
                                          const Icon(Icons.comment_outlined, size: 20),
                                          const SizedBox(width: 4),
                                          Text('${p.commentCount}'),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      InkWell(
                                        onTap: () => _share(i),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.share_outlined, size: 20),
                                            SizedBox(width: 4),
                                            Text('分享'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
