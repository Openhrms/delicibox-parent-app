import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((_) => SubscriptionService());

class SubscriptionService {
  final String _base = const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<List<Plan>> fetchPlansWithFallback() async {
    try {
      final r = await _dio.get('/api/v1/plans');
      final items = (r.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return items.map((m) => Plan.fromMap(m['id']?.toString() ?? (m['code']?.toString() ?? ''), m)).toList();
    } catch (_) {
      // fallback if API not ready
      return [
        Plan(
          id: 'MONTHLY_STD',
          code: 'MONTHLY_STD',
          name: 'Monthly Standard',
          currency: 'INR',
          priceMonth: 2499.00,
          boxesPerMonth: 22,
          pauseDaysAllowed: 5,
        ),
      ];
    }
  }

  Stream<Map<String, dynamic>?> watchActiveSub(String uid) async* {
    while (true) {
      try {
        final r = await _dio.get('/api/v1/users/$uid/subscription');
        yield (r.data == null) ? null : Map<String, dynamic>.from(r.data as Map);
      } catch (_) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> startSubscription(String uid, Plan p) async {
    // Let the server compute proration and set pending/active status
    await _dio.post('/api/v1/users/$uid/subscription', data: jsonEncode({'planCode': p.code}));
  }

  Future<void> markActive(String uid) async {
    await _dio.put('/api/v1/users/$uid/subscription', data: jsonEncode({'status': 'active'}));
  }

  Future<void> cancel(String uid) async {
    await _dio.put('/api/v1/users/$uid/subscription', data: jsonEncode({'status': 'canceled'}));
  }
}

