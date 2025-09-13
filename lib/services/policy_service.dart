import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/env.dart';

final policyServiceProvider = Provider<PolicyService>((_) => PolicyService());

class PolicyService {
  final _dio = Dio(BaseOptions(baseUrl: Env.baseUrl));

  Future<Map<String, dynamic>> fetch() async {
    try {
      final r = await _dio.get('/api/v1/config/policy');
      return Map<String, dynamic>.from(r.data as Map);
    } catch (_) {
      // sensible defaults with zero carry-forward as per your spec
      return {
        'pauseDaysPerMonth': 5,
        'allowCarryForwardCredits': false,
        'specialDonationWindows': ['dussehra','sankranti','summer'],
      };
    }
  }
}

