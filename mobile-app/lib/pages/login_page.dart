import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/carrier_phone_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  final AuthService authService;
  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _carrier = CarrierPhoneService();
  bool _loading = false;
  bool _fetchingPhone = true;
  String? _phone;
  String? _operator;
  String _tip = '';

  @override
  void initState() {
    super.initState();
    _loadCarrierPhone();
  }

  Future<void> _loadCarrierPhone() async {
    setState(() {
      _fetchingPhone = true;
      _tip = '正在通过运营商获取本机号码…';
    });
    final result = await _carrier.fetchCarrierPhone();
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _phone = result.phone;
        _operator = result.operator;
        _fetchingPhone = false;
        _tip = '已识别${_operator ?? '运营商'}号码，无需手动输入';
      });
      return;
    }
    setState(() {
      _fetchingPhone = false;
      _tip = '未能自动获取号码，请授予电话权限后重试（部分机型需插 SIM 卡）';
    });
  }

  Future<void> _ensurePhone() async {
    if (_phone != null && _phone!.length == 11) return;
    await _loadCarrierPhone();
    if (_phone == null || _phone!.length != 11) {
      throw Exception('无法获取本机号码，请检查 SIM 卡与电话权限');
    }
  }

  Future<void> _oneTapLogin() async {
    setState(() {
      _loading = true;
      _tip = '';
    });
    try {
      await _ensurePhone();
      await widget.authService.loginByCarrier(phone: _phone!, operator: _operator);
      if (!mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tip = '一键登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _browseAsGuest() async {
    setState(() {
      _loading = true;
      _tip = '';
    });
    try {
      await _ensurePhone();
      try {
        await widget.authService.loginAsGuest(_phone!);
      } catch (_) {
        await widget.authService.saveGuestPhone(_phone!);
      }
      if (!mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tip = '游客进入失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = _phone != null ? CarrierPhoneService.maskPhone(_phone!) : '获取中…';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Text(
              '模宇宙(糖艺大模王)',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('运营商认证 · 本机号码一键登录', style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 40),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Icon(Icons.sim_card_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_operator ?? '运营商', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              masked,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      if (_fetchingPhone) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tip.isEmpty ? '号码由运营商/ SIM 提供，无需手动输入' : _tip,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading || _fetchingPhone ? null : _oneTapLogin,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('本机号码一键登录'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading || _fetchingPhone ? null : _browseAsGuest,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('游客浏览（同样使用本机号码）'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loading ? null : _loadCarrierPhone,
              child: const Text('重新获取本机号码'),
            ),
            const SizedBox(height: 24),
            const Text(
              '登录即表示同意《用户协议》和《隐私政策》。我们仅用于账号识别，不会对外泄露您的手机号。',
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
