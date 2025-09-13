import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
class EventOnboarding extends ConsumerWidget {
  final AppUser user;
  const EventOnboarding({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(appBar: AppBar(title: const Text('Event setup')),
      body: const Center(child: Text('Event name • dates • quantity planning')));
  }
}
