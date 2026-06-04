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
  bool _fetchingPhone = false;
  CarrierPhoneResult? _carrierInfo;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCarrierPhone();
  }

  Future<void> _loadCarrierPhone() async {
    setState(() {
      _fetchingPhone = true;
      _error = '';
    });
    final result = await _carrier.fetchCarrierPhone();
    if (!mounted) return;
    setState(() {
      _carrierInfo = result;
      _fetchingPhone = false;
    });
  }

  Future<void> _auth({bool guest = false}) async {
    final info = _carrierInfo;
    if (info == null || !info.canAuth) {
      setState(() => _error = '本机认证未就绪，请授予电话权限后点「重试」');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      if (guest) {
        await widget.authService.loginAsGuest(
          phone: info.hasRealPhone ? info.phone : null,
          deviceId: info.deviceId,
          operator: info.operator,
        );
      } else {
        await widget.authService.loginByCarrier(
          phone: info.hasRealPhone ? info.phone : null,
          operator: info.operator,
          deviceId: info.deviceId,
        );
      }
      if (!mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg.contains('SocketException') || msg.contains('Failed host')) {
      return '网络连接失败，请检查服务器配置或网络';
    }
    return msg;
  }

  String? get _statusHint {
    if (_fetchingPhone) return '正在通过运营商认证本机…';
    if (_loading) return '正在登录…';
    final info = _carrierInfo;
    if (info == null) return null;
    if (info.hasRealPhone) {
      return '已识别 ${CarrierPhoneService.maskPhone(info.phone!)}，无需输入手机号';
    }
    if (info.canAuth) {
      return '本机号码由运营商保护，已使用本机标识完成认证';
    }
    if (info.error == 'permission_denied') {
      return '需要电话权限以完成运营商认证';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _fetchingPhone;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '模宇宙(糖艺大模王)',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '运营商认证 · 无需手动输入手机号',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              if (busy) ...[
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _statusHint ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ] else ...[
                const Spacer(),
              ],
              if (!busy) ...[
                const Spacer(),
                FilledButton(
                  onPressed: _auth,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('本机号码一键登录'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _auth(guest: true),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('游客浏览'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadCarrierPhone,
                  child: const Text('重试获取本机信息'),
                ),
              ],
              const SizedBox(height: 16),
              if (_statusHint != null && !busy)
                Text(
                  _statusHint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.deepOrange, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                '登录即表示同意《用户协议》和《隐私政策》',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
