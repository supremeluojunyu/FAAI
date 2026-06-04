import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _fetchingPhone = false;
  bool _smsMode = false;
  bool _codeSent = false;
  CarrierPhoneResult? _carrierInfo;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCarrierPhone();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
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
      if (result.hasRealPhone) {
        _phoneCtrl.text = result.phone!;
      }
    });
  }

  Future<void> _auth({bool guest = false}) async {
    final info = _carrierInfo;
    if (info == null || !info.canAuth) {
      setState(() => _error = '本机认证未就绪，请授予电话权限或使用短信登录');
      return;
    }
    if (!guest && !info.hasRealPhone) {
      setState(() {
        _smsMode = true;
        _error = '本机无法读取真实号码（系统限制），请用短信验证码登录以绑定 136 等真实手机号';
      });
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
          phone: info.phone,
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

  Future<void> _sendSmsCode() async {
    final phone = _phoneCtrl.text.trim();
    if (!CarrierPhoneService.isRealMobile(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final debug = await widget.authService.sendCode(phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        if (debug.isNotEmpty) _codeCtrl.text = debug;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(debug.isNotEmpty ? '测试验证码：$debug' : '验证码已发送')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBySms() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (!CarrierPhoneService.isRealMobile(phone) || code.length < 4) {
      setState(() => _error = '请输入手机号和验证码');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await widget.authService.loginBySms(phone: phone, code: code);
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
    if (_fetchingPhone) return '正在检测本机 SIM 与运营商…';
    if (_loading) return '正在登录…';
    if (_smsMode) return '短信登录将使用您填写的真实手机号';
    final info = _carrierInfo;
    if (info == null) return null;
    if (info.hasRealPhone) {
      return '已识别 ${CarrierPhoneService.maskPhone(info.phone!)}（${info.operator ?? "运营商"}）';
    }
    if (info.canAuth) {
      return '${info.operator ?? "运营商"}：系统未返回本机号码，请使用下方短信登录';
    }
    if (info.error == 'permission_denied') {
      return '需要电话权限；或使用短信验证码登录';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _fetchingPhone;
    final showSms = _smsMode || (_carrierInfo?.hasRealPhone != true);

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
              Text(
                showSms ? '短信验证码登录（真实手机号）' : '运营商认证登录',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              if (busy) ...[
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(_statusHint ?? '', style: const TextStyle(color: Colors.grey)),
                ),
              ],
              if (!busy) ...[
                const SizedBox(height: 24),
                if (showSms) ...[
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      hintText: '例如 13619697128',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _loading ? null : _sendSmsCode,
                        child: Text(_codeSent ? '重发' : '获取验证码'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loginBySms,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('短信验证码登录'),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  FilledButton(
                    onPressed: _auth,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('本机号码一键登录'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!showSms || _carrierInfo?.hasRealPhone == true) ...[
                  OutlinedButton(
                    onPressed: () => _auth(guest: true),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('游客浏览'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (!showSms)
                  TextButton(
                    onPressed: () => setState(() => _smsMode = true),
                    child: const Text('无法读取本机号码？使用短信登录'),
                  ),
                if (showSms && _carrierInfo?.hasRealPhone == true)
                  TextButton(
                    onPressed: () => setState(() => _smsMode = false),
                    child: const Text('返回一键登录'),
                  ),
                TextButton(
                  onPressed: _loadCarrierPhone,
                  child: const Text('重新检测本机 SIM'),
                ),
              ],
              const Spacer(),
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
                '说明：多数 Android 10+ 机型不向应用返回 SIM 本机号码，需短信登录才能绑定真实手机号。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 4),
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
