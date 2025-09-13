import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/env.dart';
import 'auth_service.dart' as mock;
import 'firebase_auth_service.dart' show FirebaseAuthService, firebaseAuthServiceProvider;
import '../models/app_user.dart';

/// Returns AuthService (mock) or FirebaseAuthService depending on Env flag.
final authAnyProvider = Provider<Object>((ref) {
  return kUseMockAuth ? mock.AuthService() : ref.read(firebaseAuthServiceProvider);
});

/// Unified "current user" provider for AppGate.
final sessionUserAnyProvider = FutureProvider<AppUser?>((ref) async {
  if (kUseMockAuth) {
    return ref.read(mock.sessionUserProvider.future);
  } else {
    final svc = ref.read(firebaseAuthServiceProvider);
    return svc.currentUser();
  }
});
