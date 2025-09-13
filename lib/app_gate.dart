import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/onboarding/onboarding_router.dart';
import 'app_shell.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionUserProvider);
    return s.when(
      loading: ()=> const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e,_)=> Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const WelcomeScreen();
        if (!user.profileComplete) return OnboardingRouter(user: user);
        return AppShell(user: user);
      },
    );
  }
}
