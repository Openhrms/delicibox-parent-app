import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase_auth_service.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose(); _new.dispose(); _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _current,
            obscureText: _obscure,
            decoration: _dec('Current password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _new,
            obscureText: _obscure,
            decoration: _dec('New password (min 8 chars)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: _dec('Confirm new password'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Text('Update password'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }

  Future<void> _submit() async {
    if (_new.text.length < 8 || _new.text != _confirm.text) {
      _snack('Passwords do not match / too short');
      return;
    }
    setState(() => _busy = true);
    try {
      final svc = ref.read(firebaseAuthServiceProvider);
      // Re-auth then change:
      // For web, we can’t read the email from a text field reliably; prompt for it in UI if needed.
      // Here we assume email/password users; phone-only users won’t use this screen.
      final user = svc.currentUser;
      final u = await user();
      if (u == null) throw Exception('Not signed in');

      await svc.reauthWithEmail(u.email, _current.text);
      await svc.changePassword(_new.text);

      if (!mounted) return;
      _snack('Password updated', ok: true);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.deepOrange),
    );
  }
}

