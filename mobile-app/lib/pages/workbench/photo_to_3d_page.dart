import 'package:flutter/material.dart';
import '../../services/workbench_service.dart';
import 'workbench_job_detail_page.dart';

class PhotoTo3DPage extends StatefulWidget {
  const PhotoTo3DPage({super.key, required this.service});
  final WorkbenchService service;

  @override
  State<PhotoTo3DPage> createState() => _PhotoTo3DPageState();
}

class _PhotoTo3DPageState extends State<PhotoTo3DPage> {
  final _imageCtrl = TextEditingController(text: "https://picsum.photos/seed/photo3d/800/600");
  final _titleCtrl = TextEditingController();
  bool _submitting = false;
  PhotoQuota? _quota;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final q = await widget.service.fetchPhotoQuota();
      if (!mounted) return;
      setState(() => _quota = q);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_imageCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final id = await widget.service.createPhotoTo3DJob(
        imageUrls: [_imageCtrl.text.trim()],
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkbenchJobDetailPage(service: widget.service, jobId: id)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("提交失败: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
      _loadQuota();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("拍照生成模型")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text("本月额度"),
              subtitle: Text(_quota == null ? "加载中..." : "${_quota!.used}/${_quota!.limit}，剩余 ${_quota!.remaining}"),
              trailing: _quota == null ? null : Text(_quota!.period),
            ),
          ),
          const SizedBox(height: 12),
          const Text("图片URL（移动端可替换为拍照/相册上传后得到的URL）"),
          const SizedBox(height: 8),
          TextField(controller: _imageCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text("模型标题"),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? "提交中..." : "开始生成"),
          ),
        ),
      ),
    );
  }
}
