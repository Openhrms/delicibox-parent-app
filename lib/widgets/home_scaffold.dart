import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/env.dart';
import '../services/firebase_auth_service.dart';
import '../services/session_user.dart';
import '../services/auth_service.dart' as mock; // used only when kUseMockAuth == true
import 'package:characters/characters.dart';

/// Generic scaffold with AppBar, bottom NavigationBar, avatar & profile menu.
class HomeScaffold extends ConsumerStatefulWidget {
  final String title;
  final List<Widget> pages;
  final List<NavigationDestination> destinations;
  final int initialIndex;

  const HomeScaffold({
    super.key,
    required this.title,
    required this.pages,
    required this.destinations,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionUserProvider).value;
    final initial = _avatarInitial(user);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProfileMenu(context),
              child: CircleAvatar(
                radius: 18,
                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: widget.pages[_idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: widget.destinations,
      ),
    );
  }

  String _avatarInitial(user) {
  if (user == null) return 'U';
  String first(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? '' : t.substring(0, 1).toUpperCase();
  }
  return first(user.displayName).isNotEmpty
      ? first(user.displayName)
      : (first(user.email).isNotEmpty ? first(user.email) : 'U');
}





  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final u = ref.read(sessionUserProvider).value;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u?.displayName ?? 'User'),
                  subtitle: Text(u?.email ?? ''),
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile-edit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('Change password'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/change-password');
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  textColor: Colors.deepOrange,
                  iconColor: Colors.deepOrange,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      if (kUseMockAuth) {
                        await ref.read(mock.authServiceProvider).logout();
                      } else {
                        await ref.read(firebaseAuthServiceProvider).logout();
                      }
                    } catch (_) {}
                    if (context.mounted) {
                      // Send back to splash which routes to auth if no session
                      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
