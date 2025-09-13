import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'firebase_auth_service.dart';

final sessionUserProvider = FutureProvider<AppUser?>((ref) async {
  final svc = ref.read(firebaseAuthServiceProvider);
  return svc.currentUser();
});
