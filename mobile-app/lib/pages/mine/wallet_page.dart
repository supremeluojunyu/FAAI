import 'package:flutter/material.dart';
import '../../models/app_config.dart';
import '../../services/config_service.dart';
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
  RechargePackagesConfig _recharge = const RechargePackagesConfig();
  WalletConfig _wallet = const WalletConfig();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cfg = await ConfigService(widget.apiBaseUrl).fetchConfig();
      final data = await UserHubService(widget.apiBaseUrl).fetchWallet();
      if (!mounted) return;
      setState(() {
        _balance = (data['balance'] ?? '0').toString();
        _recharge = cfg.rechargePackages;
        _wallet = cfg.walletConfig;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _recharge(RechargePackage pkg) async {
    try {
      final hub = UserHubService(widget.apiBaseUrl);
      await hub.recharge(amount: pkg.amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已提交充值 ${pkg.label}，待支付渠道回调后到账')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('钱包')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('账户余额', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('¥$_balance', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          if (_wallet.balanceTip.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(_wallet.balanceTip, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_recharge.enabled && _wallet.rechargeEnabled) ...[
                    const SizedBox(height: 16),
                    Text('充值', style: Theme.of(context).textTheme.titleMedium),
                    if (_recharge.notice.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(_recharge.notice, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recharge.packages.map((p) {
                        return ActionChip(
                          label: Text(p.label),
                          onPressed: () => _recharge(p),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_wallet.withdrawEnabled)
                    OutlinedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_wallet.withdrawTip.isNotEmpty ? _wallet.withdrawTip : '提现功能即将开放')),
                      ),
                      child: const Text('提现'),
                    ),
                ],
              ),
            ),
    );
  }
}
