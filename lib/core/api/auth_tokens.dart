import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _k = 'auth_tokens';
const _accessLifespan = Duration(hours: 1);      // access token lifetime
const _refreshLifespan = Duration(days: 90);     // refresh token lifetime
const _checkEvery = Duration(minutes: 1);        // background check cadence

class AuthTokens {
  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'at': accessToken,
    'ax': accessExpiresAt.toIso8601String(),
    'rt': refreshToken,
    'rx': refreshExpiresAt.toIso8601String(),
  };

  static AuthTokens fromJson(Map<String, dynamic> j) => AuthTokens(
    accessToken: j['at'],
    accessExpiresAt: DateTime.parse(j['ax']),
    refreshToken: j['rt'],
    refreshExpiresAt: DateTime.parse(j['rx']),
  );

  bool get accessValid => DateTime.now().isBefore(accessExpiresAt);
  bool get refreshValid => DateTime.now().isBefore(refreshExpiresAt);

  AuthTokens withNewAccess(String token) => AuthTokens(
    accessToken: token,
    accessExpiresAt: DateTime.now().add(_accessLifespan),
    refreshToken: refreshToken,
    refreshExpiresAt: refreshExpiresAt,
  );
}

class TokenService {
  Timer? _timer;

  Future<AuthTokens?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    if (raw == null) return null;
    return AuthTokens.fromJson(jsonDecode(raw));
  }

  Future<void> save(AuthTokens? t) async {
    final p = await SharedPreferences.getInstance();
    if (t == null) { await p.remove(_k); return; }
    await p.setString(_k, jsonEncode(t.toJson()));
  }

  /// Establishes session with fresh tokens (called on login/register).
  Future<AuthTokens> establishSession(String uid) async {
    // MOCK: generate opaque strings. Swap with server call later.
    final at = 'at-${uid}-${DateTime.now().millisecondsSinceEpoch}';
    final rt = 'rt-${uid}-${DateTime.now().millisecondsSinceEpoch}';
    final t = AuthTokens(
      accessToken: at,
      accessExpiresAt: DateTime.now().add(_accessLifespan),
      refreshToken: rt,
      refreshExpiresAt: DateTime.now().add(_refreshLifespan),
    );
    await save(t);
    _armAutoRefresh();
    return t;
  }

  /// Clears tokens on logout.
  Future<void> clear() async { await save(null); _timer?.cancel(); }

  /// Returns a valid access token, refreshing if needed.
  Future<String?> getValidAccessToken() async {
    final t = await load();
    if (t == null) return null;
    if (t.accessValid) return t.accessToken;
    if (t.refreshValid) {
      final nt = await _refreshAccess(t);
      return nt?.accessToken;
    }
    return null; // fully expired
  }

  void _armAutoRefresh() async {
    _timer?.cancel();
    _timer = Timer.periodic(_checkEvery, (_) async {
      final t = await load();
      if (t == null) return;
      final now = DateTime.now();
      final grace = t.accessExpiresAt.subtract(const Duration(minutes: 3));
      if (now.isAfter(grace) && t.refreshValid) {
        await _refreshAccess(t);
      }
    });
  }

  Future<AuthTokens?> _refreshAccess(AuthTokens t) async {
    try {
      // MOCK refresh: replace with backend call using t.refreshToken.
      final newAccess = 'at-refresh-${DateTime.now().millisecondsSinceEpoch}';
      final nt = t.withNewAccess(newAccess);
      await save(nt);
      if (kDebugMode) { /* print('Token refreshed'); */ }
      return nt;
    } catch (_) {
      return null;
    }
  }
}

final tokenServiceProvider = Provider<TokenService>((ref) {
  final svc = TokenService();
  // arm background refresh when app starts and tokens exist
  svc.load().then((t){ if (t != null) svc._armAutoRefresh(); });
  return svc;
});
