import 'package:flutter/material.dart';
import '../../services/workbench_service.dart';
import 'workbench_job_detail_page.dart';

class FoodMoldPage extends StatefulWidget {
  const FoodMoldPage({super.key, required this.service});
  final WorkbenchService service;

  @override
  State<FoodMoldPage> createState() => _FoodMoldPageState();
}

class _FoodMoldPageState extends State<FoodMoldPage> {
  final _urlCtrl = TextEditingController(text: "https://example.com/files/source_model.stl");
  final _titleCtrl = TextEditingController(text: "我的食品模具");
  int _blocks = 4;
  double _depth = 12;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final id = await widget.service.createFoodMoldJob(
        sourceModelUrl: _urlCtrl.text.trim(),
        blockCount: _blocks,
        depthMm: _depth,
        title: _titleCtrl.text.trim(),
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
      appBar: AppBar(title: const Text("食品模具制作")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("源模型URL"),
          const SizedBox(height: 8),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const Text("模具标题"),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Text("拼块数量: $_blocks"),
          Slider(
            value: _blocks.toDouble(),
            divisions: 11,
            min: 1,
            max: 12,
            label: "$_blocks",
            onChanged: (v) => setState(() => _blocks = v.round()),
          ),
          const SizedBox(height: 8),
          Text("阴刻深度: ${_depth.toStringAsFixed(1)} mm"),
          Slider(
            value: _depth,
            divisions: 79,
            min: 1,
            max: 80,
            label: _depth.toStringAsFixed(1),
            onChanged: (v) => setState(() => _depth = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? "生成中..." : "生成模具"),
          ),
        ),
      ),
    );
  }
}
