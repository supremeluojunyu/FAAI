import 'package:flutter/material.dart';
import '../../services/model_service.dart';
import '../../services/user_hub_service.dart';
import '../model_detail/model_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<ModelItem> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await UserHubService(widget.apiBaseUrl).fetchFavorites();
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('暂无收藏，去商城逛逛吧'))
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (_, i) {
                    final m = _list[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(m.coverUrl, width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      title: Text(m.title),
                      subtitle: Text('¥${m.price}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModelDetailPage(modelId: m.id))),
                    );
                  },
                ),
    );
  }
}
