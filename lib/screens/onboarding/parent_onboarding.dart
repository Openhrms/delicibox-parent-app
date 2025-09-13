import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
class ParentOnboarding extends ConsumerWidget {
  final AppUser user;
  const ParentOnboarding({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: AppBar(title: const Text('Parent setup')),
      body: const Center(child: Text('Add child details • address • preferences')));
  }
}
