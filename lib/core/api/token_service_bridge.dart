import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../shared/env.dart';

/// ---- Interface ----
abstract class ITokenService {
  Future<String?> getValidAccessToken();
  Future<void> establishSession(String uid);
  Future<void> clear();
}

/// ---- Mock implementation (keeps your previous behavior) ----
const _k = 'auth_tokens';
const _accessLifespan = Duration(hours: 1);
const _refreshLifespan = Duration(days: 90);
const _checkEvery = Duration(minutes: 1);

class _MockTokenService implements ITokenService {
  Timer? _timer;
  Future<Map<String, dynamic>?> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    return raw == null ? null : jsonDecode(raw);
  }
  Future<void> _save(Map<String, dynamic>? j) async {
    final p = await SharedPreferences.getInstance();
    if (j == null) { await p.remove(_k); return; }
    await p.setString(_k, jsonEncode(j));
  }

  @override
  Future<void> establishSession(String uid) async {
    final t = {
      'at': 'at-$uid-${DateTime.now().millisecondsSinceEpoch}',
      'ax': DateTime.now().add(_accessLifespan).toIso8601String(),
      'rt': 'rt-$uid-${DateTime.now().millisecondsSinceEpoch}',
      'rx': DateTime.now().add(_refreshLifespan).toIso8601String(),
    };
    await _save(t);
    _arm();
  }

  @override
  Future<String?> getValidAccessToken() async {
    final j = await _load();
    if (j == null) return null;
    final ax = DateTime.parse(j['ax']);
    if (DateTime.now().isBefore(ax)) return j['at'];
    final rx = DateTime.parse(j['rx']);
    if (DateTime.now().isBefore(rx)) {
      // refresh
      j['at'] = 'at-refresh-${DateTime.now().millisecondsSinceEpoch}';
      j['ax'] = DateTime.now().add(_accessLifespan).toIso8601String();
      await _save(j);
      return j['at'];
    }
    return null;
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkEvery, (_) async { await getValidAccessToken(); });
  }

  @override
  Future<void> clear() async { _timer?.cancel(); await _save(null); }
}

/// ---- Firebase implementation (uses SDK auto-refresh; ID token ~1h) ----
class _FirebaseTokenService implements ITokenService {
  @override
  Future<void> establishSession(String uid) async {
    // Nothing to persist; Firebase SDK manages refresh token (90d+) internally.
  }

  @override
  Future<String?> getValidAccessToken() async {
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    // getIdToken() refreshes if expiring or expired
    return await u.getIdToken();
  }

  @override
  Future<void> clear() async {
    await fb.FirebaseAuth.instance.signOut();
  }
}

/// ---- Factory provider ----
final tokenServiceProvider = Provider<ITokenService>((ref) {
  return kUseMockAuth ? _MockTokenService() : _FirebaseTokenService();
});
