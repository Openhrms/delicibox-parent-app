import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/user_type.dart';
import '../../services/session_user.dart';
import '../../services/profile_service.dart';
import '../../services/firebase_auth_service.dart' as fb;
import '../../services/auth_service.dart' as mock;
import '../../shared/env.dart';
import '../profile/child_editor.dart';

class ProfileTab extends ConsumerWidget {
  final String role; // e.g., 'Parent', 'Corporate'
  const ProfileTab({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uAsync = ref.watch(sessionUserProvider);
    return uAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Please login.')));
        }
        return _Body(user: user, role: role);
      },
    );
  }
}

class _Body extends ConsumerWidget {
  final AppUser user;
  final String role;
  const _Body({required this.user, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _profileHeader(context, user),
          const SizedBox(height: 14),
          _quickActions(context, ref),
          const SizedBox(height: 14),

          if (user.userType == UserType.parent) _childrenCard(context, ref, user.uid),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, AppUser u) {
    String initial(String? s) {
      final t = (s ?? '').trim();
      return t.isEmpty ? 'U' : t.substring(0, 1).toUpperCase();
    }

    final display = (u.displayName.isNotEmpty ? u.displayName : 'User');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                initial(u.displayName.isNotEmpty ? u.displayName : u.email),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(display,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(u.email, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.indigo.withOpacity(.25)),
                    ),
                    child: Text(userTypeLabel(u.userType),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton(context, Icons.edit_outlined, 'Edit Profile', () {
              Navigator.pushNamed(context, '/profile-edit');
            }),
            _actionButton(context, Icons.password_outlined, 'Change Password', () {
              Navigator.pushNamed(context, '/change-password');
            }),
            _actionButton(context, Icons.logout_outlined, 'Logout', () async {
              if (kUseMockAuth) {
                await ref.read(mock.authServiceProvider).logout();
              } else {
                await ref.read(fb.firebaseAuthServiceProvider).logout();
              }
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
              }
            }, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return SizedBox(
      width: 160, height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: danger ? Colors.deepOrange : null),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: danger ? Colors.deepOrange : Theme.of(context).colorScheme.outline),
          foregroundColor: danger ? Colors.deepOrange : null,
        ),
      ),
    );
  }

  Widget _childrenCard(BuildContext context, WidgetRef ref, String uid) {
    final svc = ref.read(profileServiceProvider);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchChildren(uid),
      builder: (ctx, snap) {
        final items = snap.data ?? const [];
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Children', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    TextButton.icon(
                      onPressed: () => _openChildEditor(context, ref, uid),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No children added yet.', style: TextStyle(color: Colors.black54)),
                  ),
                ...items.map((c) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const CircleAvatar(child: Icon(Icons.child_care_outlined)),
                      title: Text(c['name'] ?? ''),
                      subtitle: Text(_childSubtitle(c)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            _openChildEditor(context, ref, uid, initial: c);
                          } else if (v == 'delete') {
                            await ref.read(profileServiceProvider).deleteChild(uid, c['id'] as String);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Child removed'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  String _childSubtitle(Map<String, dynamic> c) {
    String t(dynamic v) => (v ?? '').toString().trim();
    final parts = <String>[];
    final klass = t(c['class']);
    final section = t(c['section']);
    final adm = t(c['admissionNo']);
    final school = t(c['schoolName']);
    if (klass.isNotEmpty) parts.add('Class: $klass');
    if (section.isNotEmpty) parts.add('Sec: $section');
    if (adm.isNotEmpty) parts.add('Adm: $adm');
    if (school.isNotEmpty) parts.add('School: $school');
    return parts.isEmpty ? 'No additional info' : parts.join(' • ');
  }

  Future<void> _openChildEditor(BuildContext context, WidgetRef ref, String uid, {Map<String, dynamic>? initial}) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChildEditor(initial: initial),
    );
    if (res == null) return;
    await ref.read(profileServiceProvider).upsertChild(
      uid,
      childId: initial?['id'] as String?,
      data: res,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(initial == null ? 'Child added' : 'Child updated'),
          backgroundColor: Colors.green),
      );
    }
  }
}

