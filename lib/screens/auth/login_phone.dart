import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPhone extends StatefulWidget {
  const LoginPhone({super.key});
  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  String _status = '';

  Future<void> _sendCode() async {
    setState(() => _status = 'Sending code...');
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      verificationCompleted: (cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        setState(() => _status = 'Auto-verified & signed in');
      },
      verificationFailed: (e) => setState(() => _status = 'Failed: ${e.code}'),
      codeSent: (verId, _) {
        setState(() {
          _verificationId = verId;
          _codeSent = true;
          _status = 'Code sent';
        });
      },
      codeAutoRetrievalTimeout: (verId) => _verificationId = verId,
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() => _status = 'Verifying...');
    final cred = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _otpCtrl.text.trim(),
    );
    await FirebaseAuth.instance.signInWithCredential(cred);
    setState(() => _status = 'Signed in');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Login (Phone OTP)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (user != null) ...[
              Text('Logged in: ${user.phoneNumber ?? user.uid}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  setState((){});
                },
                child: const Text('Sign out'),
              ),
            ] else ...[
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone (e.g. +91XXXXXXXXXX)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              if (!_codeSent)
                ElevatedButton(onPressed: _sendCode, child: const Text('Send OTP')),
              if (_codeSent) ...[
                TextField(
                  controller: _otpCtrl,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _verifyCode, child: const Text('Verify & Sign in')),
              ],
            ],
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
