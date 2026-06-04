import 'package:flutter/material.dart';
import '../../services/user_hub_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _balance = '0';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await UserHubService(widget.apiBaseUrl).fetchWallet();
      if (!mounted) return;
      setState(() {
        _balance = (data['balance'] ?? '0').toString();
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
      appBar: AppBar(title: const Text('钱包')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('账户余额', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('¥$_balance', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('充值功能对接支付渠道后开放'))),
                    child: const Text('充值'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提现需完成实名认证'))),
                    child: const Text('提现'),
                  ),
                ],
              ),
            ),
    );
  }
}
