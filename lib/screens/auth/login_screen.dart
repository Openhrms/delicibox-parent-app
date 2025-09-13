import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_type.dart';
import '../../services/auth_service.dart' as mock;
import '../../services/firebase_auth_service.dart' as fbsvc;
import '../../shared/env.dart';
import '../../shared/effects.dart';
import '../onboarding/onboarding_router.dart';
import '../../app_shell.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final UserType type;
  const LoginScreen({super.key, required this.type});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  // password login
  final _email = TextEditingController();
  final _pass = TextEditingController();
  // otp login
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _otpStage = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _tabs.dispose(); _email.dispose(); _pass.dispose(); _phone.dispose(); _code.dispose(); _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(()=> _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t){
      if (_cooldown <= 1) { t.cancel(); setState(()=> _cooldown = 0); }
      else setState(()=> _cooldown--);
    });
  }

  Future<void> _sendOtp() async {
    try {
      if (_phone.text.trim().isEmpty) throw Exception('Enter phone number');
      if (kUseMockAuth) {
        showNiceSnack(context, 'Mock mode: OTP is 123456');
        setState(()=> _otpStage = true);
        _startCooldown();
        return;
      }
      final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
      await svc.startPhoneLogin(_phone.text.trim(), codeSent: (){
        setState(()=> _otpStage = true);
        _startCooldown();
        showNiceSnack(context, 'OTP sent to ${_phone.text.trim()}');
      });
    } catch (e) {
      showNiceSnack(context, _prettyErr(e), icon: Icons.error_outline, color: Colors.deepOrange);
    }
  }

  Future<void> _confirmOtpLogin() async {
    try {
      if (kUseMockAuth) {
        if (_code.text.trim() != '123456') throw Exception('Invalid mock OTP');
        // In mock, we will "register" on the fly for OTP login if email missing:
        final u = await ref.read(mock.authServiceProvider).login(email: '${_phone.text.trim()}@mock', password: 'otp');
        _goNext(u.profileComplete, u);
        return;
      }
      final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
      final u = await svc.confirmOtpLogin(_code.text.trim(), fallbackType: widget.type);
      _goNext(false, u);
    } catch (e) {
      showNiceSnack(context, _prettyErr(e), icon: Icons.error_outline, color: Colors.deepOrange);
    }
  }

  Future<void> _submitPasswordLogin() async {
    try {
      if (kUseMockAuth) {
        final u = await ref.read(mock.authServiceProvider).login(email: _email.text.trim(), password: _pass.text);
        _goNext(u.profileComplete, u);
      } else {
        final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
        final u = await svc.loginEmail(email: _email.text.trim(), password: _pass.text);
        _goNext(false, u);
      }
    } catch (e) {
      showNiceSnack(context, _prettyErr(e), icon: Icons.error_outline, color: Colors.deepOrange);
    }
  }

  void _goNext(bool profileComplete, dynamic user) {
    if (!mounted) return;
    showNiceSnack(context, 'Welcome 👋');
    if (profileComplete) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> const AppShell()), (_) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> OnboardingRouter(user: user)), (_) => false);
    }
  }

  void _openRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_)=> RegisterScreen(type: widget.type)));
  }

  String _prettyErr(Object e) {
    final s = e.toString();
    if (s.contains('network-request-failed')) return 'Network error. Please check your connection.';
    if (s.contains('invalid-verification-code')) return 'Incorrect OTP. Please try again.';
    if (s.contains('too-many-requests')) return 'Too many attempts. Please wait and retry.';
    if (s.contains('user-not-found')) return 'No account found for this email.';
    if (s.contains('wrong-password')) return 'Wrong password.';
    return s.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign in • ${userTypeLabel(widget.type)}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelPadding: const EdgeInsets.symmetric(vertical: 10),
                  tabs: const [Text('OTP'), Text('Password')],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 330,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _otpTab(context),
                    _passwordTab(context),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _otpTab(BuildContext context) {
    return Column(
      children: [
        if (!_otpStage)
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone number (+91…)'),
            keyboardType: TextInputType.phone,
          )
        else
          TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'Enter OTP'),
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 10),
        Row(children: [
          if (!_otpStage)
            Expanded(child: ElevatedButton(onPressed: _cooldown>0 ? null : _sendOtp, child: Text(_cooldown>0 ? 'Resend in ${_cooldown}s' : 'Send OTP')))
          else ...[
            Expanded(child: OutlinedButton(onPressed: ()=> setState(()=> _otpStage=false), child: const Text('Change number'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _confirmOtpLogin, child: const Text('Verify & Continue'))),
          ],
        ]),
        const SizedBox(height: 12),
        Text('New here?', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        OutlinedButton.icon(onPressed: _openRegister, icon: const Icon(Icons.person_add_alt), label: const Text('Create account')),
      ],
    );
  }

  Widget _passwordTab(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 8),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitPasswordLogin, child: const Text('Login'))),
        const SizedBox(height: 12),
        Text('Don’t have an account?', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        OutlinedButton.icon(onPressed: _openRegister, icon: const Icon(Icons.person_add_alt), label: const Text('Create account')),
      ],
    );
  }
}
