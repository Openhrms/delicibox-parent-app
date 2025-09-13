import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileServiceProvider = Provider<ProfileService>((_) => ProfileService());

class ProfileService {
  final String _base = const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  // ---- PROFILE ----
  Stream<Map<String, dynamic>?> watchProfile(String uid) async* {
    while (true) {
      try {
        final r = await _dio.get('/api/v1/users/$uid/profile');
        yield Map<String, dynamic>.from(r.data as Map);
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 10)); // light polling
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _dio.put('/api/v1/users/$uid/profile', data: jsonEncode(data));
  }

  // ---- CHILDREN ----
  Stream<List<Map<String, dynamic>>> watchChildren(String uid) async* {
    while (true) {
      try {
        final r = await _dio.get('/api/v1/users/$uid/children');
        yield (r.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        yield const <Map<String, dynamic>>[];
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> upsertChild(String uid, {String? childId, required Map<String, dynamic> data}) async {
    if (childId == null) {
      await _dio.post('/api/v1/users/$uid/children', data: jsonEncode(data));
    } else {
      await _dio.put('/api/v1/users/$uid/children/$childId', data: jsonEncode(data));
    }
  }

  Future<void> deleteChild(String uid, String childId) async {
    await _dio.delete('/api/v1/users/$uid/children/$childId');
  }
}



