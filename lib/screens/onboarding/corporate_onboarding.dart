import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
class CorporateOnboarding extends ConsumerWidget {
  final AppUser user;
  const CorporateOnboarding({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: AppBar(title: const Text('Corporate setup')),
      body: const Center(child: Text('Company details • billing • locations')));
  }
}
