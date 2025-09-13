import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/env.dart';
import 'firebase_init.dart';
import 'core/net/status_banner.dart';

// Routes & shells
import 'screens/splash/intro_video_screen.dart';
import 'app_shell.dart'; // hosts HomeRouter for dashboards
import 'screens/profile/edit_profile_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/subscriptions/subscription_screen.dart';
import 'screens/donate/donate_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kUseMockAuth) {
      await initFirebase();
    }
    runApp(const ProviderScope(child: DeliciBoxApp()));
  }, (e, st) {
    // TODO: hook crash reporting here
  });
}

class DeliciBoxApp extends StatelessWidget {
  const DeliciBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeliciBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // In your Flutter version, ThemeData.cardTheme expects CardThemeData
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0x0A000000),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const Align(
            alignment: Alignment.topCenter,
            child: NetStatusBanner(),
          ),
        ],
      ),
      // Start with the intro video; it will navigate to /app (dashboards) if session is active,
      // otherwise to your login/auth flow (inside the intro screen logic).
      home: const IntroVideoScreen(),
      routes: {
        '/app': (_) => const AppShell(), // AppShell -> HomeRouter -> role dashboards
        '/profile-edit': (_) => const EditProfileScreen(),
        '/change-password': (_) => const ChangePasswordScreen(),
        '/subscriptions': (_) => const SubscriptionScreen(),
        '/donations': (_) => const DonationsScreen(),
      },
    );
  }
}

