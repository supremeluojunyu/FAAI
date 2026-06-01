import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _wechatCode = TextEditingController();
  bool _loading = false;
  String _tip = '';

  bool _isValidPhone(String phone) => RegExp(r'^1\d{10}$').hasMatch(phone);

  Future<void> _browseAsGuest() async {
    final phone = _phone.text.trim();
    if (!_isValidPhone(phone)) {
      setState(() => _tip = '请输入11位有效手机号');
      return;
    }
    setState(() {
      _loading = true;
      _tip = '';
    });
    try {
      await widget.authService.loginAsGuest(phone);
    } catch (_) {
      await widget.authService.saveGuestPhone(phone);
    }
    if (!mounted) return;
    widget.onLoginSuccess();
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (!_isValidPhone(phone)) {
      setState(() => _tip = '请先输入有效手机号');
      return;
    }
    setState(() => _loading = true);
    try {
      final debugCode = await widget.authService.sendCode(phone);
      if (!mounted) return;
      setState(() => _tip = debugCode.isEmpty ? '验证码已发送' : '开发验证码：$debugCode');
    } catch (e) {
      if (!mounted) return;
      setState(() => _tip = '发送失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginBySms() async {
    setState(() => _loading = true);
    try {
      await widget.authService.loginBySms(phone: _phone.text.trim(), code: _code.text.trim());
      if (!mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tip = '登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginByWechatCode() async {
    setState(() => _loading = true);
    try {
      await widget.authService.loginByWechatCode(_wechatCode.text.trim());
      if (!mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _tip = '微信登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('欢迎使用')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '模宇宙(糖艺大模王)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('填写手机号即可游客浏览，无需验证码', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            decoration: const InputDecoration(
              labelText: '手机号',
              hintText: '请输入11位手机号',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _browseAsGuest,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('游客浏览'),
          ),
          const Divider(height: 40),
          const Text('完整登录（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: '验证码'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _loading ? null : _sendCode,
                child: const Text('发码'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading ? null : _loginBySms,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('验证码登录'),
          ),
          const Divider(height: 32),
          const Text('微信登录（联调模式）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _wechatCode,
            decoration: const InputDecoration(labelText: '微信授权 code'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading ? null : _loginByWechatCode,
            child: const Text('微信 code 登录'),
          ),
          if (_tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_tip, style: const TextStyle(color: Colors.deepOrange)),
          ],
        ],
      ),
    );
  }
}
