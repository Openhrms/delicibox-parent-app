import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/env.dart';
import '../../shared/effects.dart';
import '../../models/user_type.dart';
import '../onboarding/onboarding_router.dart';
import '../../services/auth_service.dart' as mock;
import '../../services/firebase_auth_service.dart' as fbsvc;
import 'package:firebase_auth/firebase_auth.dart'; // for FirebaseAuthException

class RegisterScreen extends ConsumerStatefulWidget {
  final UserType type;
  const RegisterScreen({super.key, required this.type});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // stage0: details → Send OTP; stage1: verify → Create account
  int _stage = 0;

  // controllers
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();

  // role-specific
  final _company = TextEditingController();
  final _event = TextEditingController();
  final _school = TextEditingController();
  final _extra1 = TextEditingController(); // e.g., counts

  bool _obscure = true;
  bool _agree = false;

  // cooldown for OTP resend
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose();
    _password.dispose(); _confirm.dispose(); _otp.dispose();
    _company.dispose(); _event.dispose(); _school.dispose(); _extra1.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    final color = userTypeColor(widget.type);
    final size = MediaQuery.of(context).size;
    final maxW = math.min(600.0, size.width - 24);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF4F6FB), Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: _card(color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color color) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withOpacity(.15), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(color),
            const SizedBox(height: 14),
            if (_stage == 0) ...[
              _commonFields(),
              const SizedBox(height: 12),
              _roleFields(),
              const SizedBox(height: 12),
              _termsRow(),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _canSendOtp ? _sendOtp : null,
                  child: const Text('Send OTP'),
                ),
              ),
            ] else ...[
              _otpStep(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(Color color) {
    return Column(
      children: [
        // role chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(.45), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(userTypeIcon(widget.type), size: 18, color: color),
              const SizedBox(width: 6),
              Text(userTypeLabel(widget.type),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, letterSpacing: .2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Create your DeliciBox account',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('We’ll verify your mobile number with an OTP.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
      ],
    );
  }

  // ------------------- FIELDS -------------------
  Widget _commonFields() {
    return Column(
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
          decoration: const InputDecoration(
            labelText: 'Mobile number (+91…)',
            prefixIcon: Icon(Icons.phone_iphone),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password (min 8 chars)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
        ),
      ],
    );
  }

  Widget _roleFields() {
    switch (widget.type) {
      case UserType.parent:
        return Column(children: [
          TextField(
            controller: _extra1,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of children (optional)',
              prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
          ),
        ]);
      case UserType.corporate:
        return Column(children: [
          TextField(
            controller: _company,
            decoration: const InputDecoration(
              labelText: 'Company name',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _extra1,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Employees to enroll (approx)',
              prefixIcon: Icon(Icons.group_outlined),
            ),
          ),
        ]);
      case UserType.event:
        return Column(children: [
          TextField(
            controller: _event,
            decoration: const InputDecoration(
              labelText: 'Event name',
              prefixIcon: Icon(Icons.event_available_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _extra1,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Expected attendees',
              prefixIcon: Icon(Icons.confirmation_num_outlined),
            ),
          ),
        ]);
      case UserType.general:
        return Column(children: [
          TextField(
            controller: _extra1,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Family size (optional)',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
        ]);
      case UserType.school:
        return Column(children: [
          TextField(
            controller: _school,
            decoration: const InputDecoration(
              labelText: 'School name',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _extra1,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Students (approx)',
              prefixIcon: Icon(Icons.people_outline),
            ),
          ),
        ]);
      case UserType.staff:
        return Column(children: [
          TextField(
            controller: _company,
            decoration: const InputDecoration(
              labelText: 'Organization',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
        ]);
    }
  }

  Widget _termsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'I agree to the '),
              TextSpan(text: 'Terms', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' and '),
              TextSpan(text: 'Privacy Policy', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text('OTP sent to ${_phone.text.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: _cooldown > 0 ? null : _sendOtp,
                child: Text(_cooldown > 0 ? 'Resend (${_cooldown}s)' : 'Resend'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(
            labelText: 'Enter OTP',
            prefixIcon: Icon(Icons.sms),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _canCreate ? _createAccount : null,
            child: const Text('Verify & Create account'),
          ),
        ),
      ],
    );
  }

  // ------------------- ACTIONS -------------------
  bool get _canSendOtp {
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_email.text.trim());
    final phoneOk = _phone.text.trim().length >= 10;
    final nameOk = _name.text.trim().length >= 3;
    final passOk = _password.text.length >= 8 && _password.text == _confirm.text;
    return emailOk && phoneOk && nameOk && passOk && _agree;
  }

  bool get _canCreate => _otp.text.trim().length == 6;

  Future<void> _sendOtp() async {
  try {
    if (!_canSendOtp) {
      showNiceSnack(context, 'Please complete the form and accept Terms.',
          icon: Icons.error_outline, color: Colors.deepOrange);
      return;
    }

    if (kUseMockAuth) {
      setState(() => _stage = 1);
      _startCooldown();
      showNiceSnack(context, 'Mock OTP is 123456');
      return;
    }

    final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
    await svc.startPhoneLogin(_phone.text.trim(), codeSent: () {
      setState(() => _stage = 1);
      _startCooldown();
      showNiceSnack(context, 'OTP sent to ${_phone.text.trim()}');
    });
  } catch (e) {
    showNiceSnack(context, _pretty(e),
        icon: Icons.error_outline, color: Colors.deepOrange);
  }
}




    Future<void> _createAccount() async {
  try {
    if (kUseMockAuth) {
      // Minimal mock path; no server calls
      final user = {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'type': widget.type.name,
      };
      _onRegistered(user);
      return;
    }

    final svc = ref.read(fbsvc.firebaseAuthServiceProvider);
    final u = await svc.registerWithOtpAndPassword(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      smsCode: _otp.text.trim(),
      type: widget.type,
    );
    _onRegistered(u);
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'email-already-in-use':
        showNiceSnack(context, 'This email is already registered.', icon: Icons.error_outline, color: Colors.deepOrange);
        break;
      case 'invalid-verification-code':
        showNiceSnack(context, 'Incorrect OTP. Please try again.', icon: Icons.error_outline, color: Colors.deepOrange);
        break;
      case 'missing-verificationId':
      case 'missing-confirmation':
        showNiceSnack(context, 'Please request a new OTP.', icon: Icons.error_outline, color: Colors.deepOrange);
        break;
      default:
        showNiceSnack(context, e.message ?? e.code, icon: Icons.error_outline, color: Colors.deepOrange);
    }
  } catch (e) {
    showNiceSnack(context, _pretty(e), icon: Icons.error_outline, color: Colors.deepOrange);
  }
}



  void _onRegistered(dynamic user) {
  if (!mounted) return;
  showNiceSnack(context, 'Welcome to DeliciBox 🎉');
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => OnboardingRouter(user: user)),
    (_) => false,
  );
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

  String _pretty(Object e) {
    final s = e.toString();
    return s.replaceFirst('Exception: ', '');
  }

  Map<String, dynamic> _metaForType() {
    switch (widget.type) {
      case UserType.parent:
        return {'childrenCount': int.tryParse(_extra1.text.trim() == '' ? '0' : _extra1.text.trim()) ?? 0};
      case UserType.corporate:
        return {
          'company': _company.text.trim(),
          'employeesPlanned': int.tryParse(_extra1.text.trim() == '' ? '0' : _extra1.text.trim()) ?? 0
        };
      case UserType.event:
        return {
          'eventName': _event.text.trim(),
          'attendees': int.tryParse(_extra1.text.trim() == '' ? '0' : _extra1.text.trim()) ?? 0
        };
      case UserType.general:
        return {'familySize': int.tryParse(_extra1.text.trim() == '' ? '0' : _extra1.text.trim()) ?? 0};
      case UserType.school:
        return {
          'schoolName': _school.text.trim(),
          'studentsApprox': int.tryParse(_extra1.text.trim() == '' ? '0' : _extra1.text.trim()) ?? 0
        };
      case UserType.staff:
        return {'organization': _company.text.trim()};
    }
  }
}
