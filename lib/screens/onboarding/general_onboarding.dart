import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
class GeneralOnboarding extends ConsumerWidget {
  final AppUser user;
  const GeneralOnboarding({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: AppBar(title: const Text('General setup')),
      body: const Center(child: Text('Address • preferences')));
  }
}
