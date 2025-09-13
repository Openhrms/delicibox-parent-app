// lib/services/firebase_auth_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_type.dart';

class FirebaseAuthService {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  // Phone-OTP state
  ConfirmationResult? _webConfirmation;
  String? _verificationId;

  Future<AppUser?> currentUser() async {
    final u = _fa.currentUser;
    if (u == null) return null;
    final display = u.displayName ?? '';
    final email = u.email ?? (u.phoneNumber ?? '');
    return AppUser(
      uid: u.uid,
      email: email,
      displayName: display,
      userType: UserType.parent,
      profileComplete: false,
    );
  }

  // Email/Password sign-in
  Future<AppUser> loginEmail({required String email, required String password}) async {
    final cred = await _fa.signInWithEmailAndPassword(email: email, password: password);
    final u = cred.user!;
    return AppUser(
      uid: u.uid,
      email: u.email ?? email,
      displayName: u.displayName ?? '',
      userType: UserType.parent,
      profileComplete: false,
    );
  }

  // Forgot password
  Future<void> forgotPassword(String email) async => _fa.sendPasswordResetEmail(email: email);

  // Start phone-OTP flow
  Future<void> startPhoneLogin(String phone, {required void Function() codeSent}) async {
    if (kIsWeb) {
      _webConfirmation = await _fa.signInWithPhoneNumber(phone);
      codeSent();
    } else {
      await _fa.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (_) {},
        verificationFailed: (e) { throw e; },
        codeSent: (verId, _) { _verificationId = verId; codeSent(); },
        codeAutoRetrievalTimeout: (verId) { _verificationId = verId; },
      );
    }
  }

  /// Registration: FullName + Email + Phone + Password + OTP (links both factors)
  Future<AppUser> registerWithOtpAndPassword({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String smsCode,
    required UserType type,
  }) async {
    if (kIsWeb) {
      if (_webConfirmation == null) {
        throw FirebaseAuthException(code: 'missing-confirmation', message: 'Please request OTP again.');
      }
      final phoneRes = await _webConfirmation!.confirm(smsCode);
      final phoneUser = phoneRes.user!;
      final emailCred = EmailAuthProvider.credential(email: email, password: password);
      await phoneUser.linkWithCredential(emailCred);
      await phoneUser.updateDisplayName(fullName);
      final u = _fa.currentUser!;
      return AppUser(uid: u.uid, email: email, displayName: fullName, userType: type, profileComplete: false);
    } else {
      if (_verificationId == null) {
        throw FirebaseAuthException(code: 'missing-verificationId', message: 'Please request OTP again.');
      }
      final phoneCred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
      final emailRes = await _fa.createUserWithEmailAndPassword(email: email, password: password);
      final emailUser = emailRes.user!;
      await emailUser.updateDisplayName(fullName);
      await emailUser.linkWithCredential(phoneCred);
      final u = _fa.currentUser!;
      return AppUser(uid: u.uid, email: email, displayName: fullName, userType: type, profileComplete: false);
    }
  }

  // SDK-safe stub (we enforce uniqueness via Firebase error / our backend)
  Future<bool> emailExists(String email) async {
    return false;
  }

  // OTP-only login (not registration)
  Future<AppUser> confirmOtpLogin(String smsCode, {UserType fallbackType = UserType.parent}) async {
    UserCredential cred;
    if (kIsWeb) {
      if (_webConfirmation == null) {
        throw FirebaseAuthException(code: 'missing-confirmation', message: 'Start OTP first');
      }
      cred = await _webConfirmation!.confirm(smsCode);
    } else {
      if (_verificationId == null) {
        throw FirebaseAuthException(code: 'missing-verificationId', message: 'Start OTP first');
      }
      final phoneCred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: smsCode);
      cred = await _fa.signInWithCredential(phoneCred);
    }
    final u = cred.user!;
    return AppUser(
      uid: u.uid,
      email: u.phoneNumber ?? '',
      displayName: u.displayName ?? '',
      userType: fallbackType,
      profileComplete: false,
    );
  }

  // Re-authenticate (needed before password change if session is old)
  Future<void> reauthWithEmail(String email, String password) async {
    final user = _fa.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    }
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    final user = _fa.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    }
    await user.updatePassword(newPassword);
  }

  Future<void> logout() async => _fa.signOut();
}

// Riverpod provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);
