import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/env.dart';
import '../../shared/effects.dart';
import '../../app_shell.dart';
import '../onboarding/onboarding_router.dart';
import '../../services/auth_service.dart' as mock;
import '../../services/firebase_auth_service.dart' as fbsvc;
import 'user_type_picker.dart';
import 'dart:math' as math;

class AuthHub extends ConsumerStatefulWidget {
  const AuthHub({super.key});
  @override
  ConsumerState<AuthHub> createState() => _AuthHubState();
}

class _AuthHubState extends ConsumerState<AuthHub> with SingleTickerProviderStateMixin {
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
    _tabs.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    try {
      if (_phone.text.trim().isEmpty) throw Exception('Enter phone number');
      if (kUseMockAuth) {
        showNiceSnack(context, 'Mock mode: OTP is 123456');
        setState(() => _otpStage = true);
        _startCooldown();
        return;
      }
      final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
      await svc.startPhoneLogin(_phone.text.trim(), codeSent: () {
        setState(() => _otpStage = true);
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
        final u = await ref.read(mock.authServiceProvider).login(email: '${_phone.text.trim()}@mock', password: 'otp');
        _goNext(u.profileComplete, u);
        return;
      }
      final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
      final u = await svc.confirmOtpLogin(_code.text.trim());
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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AppShell()), (_) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OnboardingRouter(user: user)), (_) => false);
    }
  }

  void _openRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserTypePickerScreen()));
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
  final size = MediaQuery.of(context).size;
  final maxW = size.width < 420 ? size.width - 24 : 420.0;

  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        _bg(), // <-- no arguments now
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: _glassCard(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  // ---------- UI PARTS ----------

  Widget _bg() {
  return const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF4F6FB), Color(0xFFFFFFFF)],
      ),
    ),
  );
  }



  Widget _glassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // brand
              _brandHeader(),
              const SizedBox(height: 12),
              _segmentedTabs(),
              const SizedBox(height: 12),
              SizedBox(
                height: 220, // compact; avoids tall/ugly feeling
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _otpTab(context),
                    _passwordTab(context),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 24),
              Text('New here?', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create account'),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _openRegister,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Responsive logo height: 35–38% of card width, clamped 72–160 px
      final double logoH =
          math.max(72.0, math.min(160.0, constraints.maxWidth * 0.38));
      final double gap = logoH > 110 ? 12 : 8;

      return Column(
        children: [
          // Transparent PNG logo
          Image.asset(
            'assets/images/LoginBG.png', // exact case
            height: logoH,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          SizedBox(height: gap),
          Text(
            'Welcome to DeliciBox',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111111),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in with OTP or Password',
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      );
    },
  );
}


  Widget _segmentedTabs() {
  const active = Color(0xFF6C63FF);

  return Container(
    height: 60, // taller so icon+text fit comfortably
    decoration: BoxDecoration(
      color: const Color(0xFFF2F3F8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x11000000)),
    ),
    child: TabBar(
      controller: _tabs,

      // No underline
      dividerColor: Colors.transparent,

      // Make the highlight span the whole tab (half of the pill)
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.all(6),
      indicator: BoxDecoration(
        color: active,
        borderRadius: BorderRadius.circular(14),
      ),

      // Typography / padding tuned to avoid overflow
      labelPadding: EdgeInsets.zero,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black87,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),

      tabs: const [
        Tab(
          height: 48, // ensures internal layout doesn’t exceed the pill
          iconMargin: EdgeInsets.only(bottom: 2), // reduce vertical spacing
          icon: Icon(Icons.sms_rounded, size: 20),
          text: 'OTP',
        ),
        Tab(
          height: 48,
          iconMargin: EdgeInsets.only(bottom: 2),
          icon: Icon(Icons.lock_outline, size: 20),
          text: 'Password',
        ),
      ],
    ),
  );
}



  Widget _otpTab(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !_otpStage
              ? TextField(
                  key: const ValueKey('phone'),
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (+91…)',
                    prefixIcon: Icon(Icons.phone_iphone),
                  ),
                  keyboardType: TextInputType.phone,
                )
              : TextField(
                  key: const ValueKey('otp'),
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.sms),
                  ),
                  keyboardType: TextInputType.number,
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (!_otpStage)
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _cooldown > 0 ? null : _sendOtp,
                  child: Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Send OTP'),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _otpStage = false),
                  child: const Text('Change number'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _confirmOtpLogin,
                  child: const Text('Verify & Continue'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _passwordTab(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pass,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _submitPasswordLogin, child: const Text('Login')),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              final c = TextEditingController(text: _email.text.trim());
              showDialog(context: context, builder: (ctx) {
                return AlertDialog(
                  title: const Text('Forgot password'),
                  content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Email')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (kUseMockAuth) {
                            await ref.read(mock.authServiceProvider).forgotPassword(c.text.trim());
                          } else {
                            await ref.read(fbsvc.firebaseAuthServiceProvider).forgotPassword(c.text.trim());
                          }
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          showNiceSnack(context, 'If the email exists, a reset link has been sent 📧');
                        } catch (e) {
                          showNiceSnack(context, e.toString(), icon: Icons.error_outline, color: Colors.deepOrange);
                        }
                      },
                      child: const Text('Send reset'),
                    ),
                  ],
                );
              });
            },
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }
}

