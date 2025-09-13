
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/user_type.dart';
import '../../services/session_user.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController(); // corporate/staff
  final _event = TextEditingController();   // event
  final _school = TextEditingController();  // school
  final _extra = TextEditingController();   // numeric fields

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _event.dispose();
    _school.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uAsync = ref.watch(sessionUserProvider);
    return uAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (u) {
        if (u == null) return const _NotLoggedIn();
        return _Body(
          user: u,
          name: _name,
          phone: _phone,
          company: _company,
          event: _event,
          school: _school,
          extra: _extra,
          saving: _saving,
          onSave: _save,
        );
      },
    );
  }

  Future<void> _save(AppUser user, UserType type) async {
    setState(() => _saving = true);
    try {
      final svc = ref.read(profileServiceProvider);
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'userType': type.name,
      };

      switch (type) {
        case UserType.parent:
          data['childrenCount'] = int.tryParse(_extra.text.trim()) ?? 0;
          break;
        case UserType.corporate:
          data['company'] = _company.text.trim();
          data['employeesPlanned'] = int.tryParse(_extra.text.trim()) ?? 0;
          break;
        case UserType.event:
          data['eventName'] = _event.text.trim();
          data['attendees'] = int.tryParse(_extra.text.trim()) ?? 0;
          break;
        case UserType.general:
          data['familySize'] = int.tryParse(_extra.text.trim()) ?? 0;
          break;
        case UserType.school:
          data['schoolName'] = _school.text.trim();
          data['studentsApprox'] = int.tryParse(_extra.text.trim()) ?? 0;
          break;
        case UserType.staff:
          data['organization'] = _company.text.trim();
          break;
      }

      await svc.updateProfile(user.uid, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.deepOrange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Body extends ConsumerWidget {
  final AppUser user;
  final TextEditingController name, phone, company, event, school, extra;
  final bool saving;
  final Future<void> Function(AppUser, UserType) onSave;

  const _Body({
    required this.user,
    required this.name,
    required this.phone,
    required this.company,
    required this.event,
    required this.school,
    required this.extra,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(profileServiceProvider);
    return StreamBuilder<Map<String, dynamic>?>(
      stream: svc.watchProfile(user.uid),
      builder: (ctx, snap) {
        final data = snap.data ?? {};
        name.text = (data['name'] ?? user.displayName ?? '').toString();
        phone.text = (data['phone'] ?? '').toString();

        final type = user.userType;

        return Scaffold(
          appBar: AppBar(title: const Text('Edit profile')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _identityCard(context, type),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: saving ? null : () => onSave(user, type),
                  child: saving
                      ? const CircularProgressIndicator()
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _identityCard(BuildContext context, UserType type) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Basic info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile (E.164: +91…)',
                prefixIcon: Icon(Icons.phone_iphone_outlined),
              ),
            ),
            const Divider(height: 24),
            _roleFields(type),
          ],
        ),
      ),
    );
  }

  Widget _roleFields(UserType type) {
    switch (type) {
      case UserType.parent:
        return Column(children: [
          TextField(
            controller: extra,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Children count (optional)',
              prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
          ),
        ]);
      case UserType.corporate:
        return Column(children: [
          TextField(
            controller: company,
            decoration: const InputDecoration(
              labelText: 'Company name',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: extra,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Employees to enroll (approx)',
              prefixIcon: Icon(Icons.groups_2_outlined),
            ),
          ),
        ]);
      case UserType.event:
        return Column(children: [
          TextField(
            controller: event,
            decoration: const InputDecoration(
              labelText: 'Event name',
              prefixIcon: Icon(Icons.event_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: extra,
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
            controller: extra,
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
            controller: school,
            decoration: const InputDecoration(
              labelText: 'School name',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: extra,
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
            controller: company,
            decoration: const InputDecoration(
              labelText: 'Organization',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
        ]);
    }
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Please login to edit profile')),
    );
  }
}

