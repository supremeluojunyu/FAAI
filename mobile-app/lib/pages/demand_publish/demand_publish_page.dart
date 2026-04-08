import 'package:flutter/material.dart';

class DemandPublishPage extends StatefulWidget {
  const DemandPublishPage({super.key});

  @override
  State<DemandPublishPage> createState() => _DemandPublishPageState();
}

class _DemandPublishPageState extends State<DemandPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _budget = TextEditingController();
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发布需求')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {}
            },
            child: const Text('发布需求并支付担保金'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: '标题'), validator: (v) => (v == null || v.isEmpty) ? '请输入标题' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _desc, maxLines: 5, decoration: const InputDecoration(labelText: '描述'), validator: (v) => (v == null || v.length < 10) ? '描述至少10字' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _budget, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '预算(¥)'), validator: (v) => (double.tryParse(v ?? '') == null) ? '请输入有效金额' : null),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_deadline == null ? '选择截止日期' : _deadline.toString().split(' ').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final now = DateTime.now();
                final v = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)), initialDate: now);
                if (v != null) setState(() => _deadline = v);
              },
            )
          ],
        ),
      ),
    );
  }
}
