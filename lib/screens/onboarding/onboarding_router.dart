import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/user_type.dart';
import 'parent_onboarding.dart';
import 'corporate_onboarding.dart';
import 'event_onboarding.dart';
import 'general_onboarding.dart';
import 'school_onboarding.dart';

class OnboardingRouter extends ConsumerWidget {
  final AppUser user;
  const OnboardingRouter({super.key, required this.user});

  static Future<void> complete(BuildContext ctx, WidgetRef ref, AppUser user) async {
    Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_)=> OnboardingRouter(user: user)), (_) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = user.userType;
    switch (t) {
      case UserType.parent: return ParentOnboarding(user: user);
      case UserType.corporate: return CorporateOnboarding(user: user);
      case UserType.event: return EventOnboarding(user: user);
      case UserType.general: return GeneralOnboarding(user: user);
      case UserType.school: return SchoolOnboarding(user: user);
      case UserType.staff: return const _SimpleDone(title: 'Staff', tip: 'Login to Ops Console');
    }
  }
}

class _SimpleDone extends StatelessWidget {
  final String title, tip;
  const _SimpleDone({required this.title, required this.tip, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('$title setup')),
      body: Center(child: Text(tip)));
  }
}
