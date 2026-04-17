import 'package:flutter/material.dart';
import '../../services/workbench_service.dart';
import 'workbench_job_detail_page.dart';

class UploadModelPage extends StatefulWidget {
  const UploadModelPage({super.key, required this.service});
  final WorkbenchService service;

  @override
  State<UploadModelPage> createState() => _UploadModelPageState();
}

class _UploadModelPageState extends State<UploadModelPage> {
  final _nameCtrl = TextEditingController(text: "sample_model.glb");
  final _urlCtrl = TextEditingController(text: "https://example.com/files/sample_model.glb");
  final _coverCtrl = TextEditingController(text: "https://picsum.photos/seed/upload/600/600");
  final _sizeCtrl = TextEditingController(text: "12582912");
  String _format = "GLB";
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final id = await widget.service.createUploadJob(
        fileName: _nameCtrl.text.trim(),
        format: _format,
        fileSize: int.tryParse(_sizeCtrl.text.trim()) ?? 1024,
        downloadUrl: _urlCtrl.text.trim(),
        coverUrl: _coverCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkbenchJobDetailPage(service: widget.service, jobId: id)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("提交失败: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("上传模型")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("文件名"),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text("格式"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _format,
            items: const ["GLB", "GLTF", "OBJ", "STL", "FBX"].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => _format = v ?? "GLB"),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          const Text("文件大小(Byte)"),
          const SizedBox(height: 8),
          TextField(controller: _sizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text("模型下载URL"),
          const SizedBox(height: 8),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text("封面URL"),
          const SizedBox(height: 8),
          TextField(controller: _coverCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? "提交中..." : "上传并解析"),
          ),
        ),
      ),
    );
  }
}
