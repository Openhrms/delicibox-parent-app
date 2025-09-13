import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/user_type.dart';
import '../shared/env.dart' as appenv;
import '../core/api/auth_tokens.dart'; // <-- use the concrete TokenService here

class AuthService {
  static const _kUsers = 'mock_users';
  static const _kSession = 'mock_session';

  final TokenService _tokens = TokenService();

  Future<AppUser?> currentUser() async {
    final p = await SharedPreferences.getInstance();
    final sid = p.getString(_kSession);
    if (sid == null) return null;
    final map = _loadUsers(p);
    final raw = map[sid];
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw));
  }

  // ----- Login (email & password) -----
  Future<AppUser> login({required String email, required String password}) async {
    final p = await SharedPreferences.getInstance();
    final users = _loadUsers(p);
    final raw = users[email];
    if (raw == null) throw Exception('No account found');
    final j = jsonDecode(raw);
    if (j['password'] != password) throw Exception('Wrong password');
    if (j['active'] == false) throw Exception('Account is inactive');
    final u = AppUser.fromJson(j);
    await p.setString(_kSession, email);
    await _tokens.establishSession(u.uid);
    return u;
  }

  // ----- Registration (email + password + phone) with unique checks -----
  Future<AppUser> registerFull({
    required String email,
    required String password,
    required String phone,
    required UserType type,
    required String displayName,
  }) async {
    assert(appenv.kUseMockAuth, 'Switch to Firebase later');
    final p = await SharedPreferences.getInstance();
    final users = _loadUsers(p);

    if (users.containsKey(email)) {
      throw Exception('An account already exists with this email.');
    }
    for (final raw in users.values) {
      final j = jsonDecode(raw);
      if ((j['phone'] ?? '') == phone) {
        throw Exception('An account already exists with this mobile number.');
      }
    }

    final u = AppUser(uid: email, email: email, displayName: displayName, userType: type, profileComplete: false);
    final m = u.toJson()
      ..['password'] = password
      ..['active'] = true
      ..['phone'] = phone;
    users[email] = jsonEncode(m);
    await p.setString(_kUsers, jsonEncode(users));
    await p.setString(_kSession, email);
    await _tokens.establishSession(u.uid);
    return u;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSession);
    await _tokens.clear();
  }

  Future<void> forgotPassword(String email) async {
    final p = await SharedPreferences.getInstance();
    final users = _loadUsers(p);
    if (!users.containsKey(email)) throw Exception('No account found for $email');
  }

  Future<void> markProfileComplete(AppUser user) async {
    final p = await SharedPreferences.getInstance();
    final users = _loadUsers(p);
    final j = jsonDecode(users[user.uid] ?? '{}');
    j['profileComplete'] = true;
    users[user.uid] = jsonEncode(j);
    await p.setString(_kUsers, jsonEncode(users));
  }

  Map<String,String> _loadUsers(SharedPreferences p) {
    final raw = p.getString(_kUsers);
    if (raw == null || raw.isEmpty) return {};
    final Map data = jsonDecode(raw);
    return data.map<String,String>((k,v)=>MapEntry(k.toString(), v.toString()));
  }
}

final authServiceProvider = Provider<AuthService>((ref)=>AuthService());

final sessionUserProvider = FutureProvider<AppUser?>((ref) async {
  final svc = ref.read(authServiceProvider);
  return svc.currentUser();
});
