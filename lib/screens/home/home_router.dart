import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_type.dart';
import '../../services/session_user.dart';
import '../auth/auth_hub.dart';

import 'role_shells.dart';

class HomeRouter extends ConsumerWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionUserProvider);
    return u.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const AuthHub();
        switch (user.userType) {
          case UserType.parent:   return ParentShell(user: user);
          case UserType.corporate:return CorporateShell(user: user);
          case UserType.event:    return EventShell(user: user);
          case UserType.general:  return GeneralShell(user: user);
          case UserType.school:   return SchoolShell(user: user);
          case UserType.staff:    return StaffShell(user: user);
        }
      },
    );
  }
}
