import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final Dio _dio;
  ApiService(String baseUrl)
      : _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

  Future<void> registerUserInBackend({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String userType,
    required Map<String, dynamic> meta,
  }) async {
    final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
    await _dio.post('/v1/users',
      data: {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'meta': meta,
        'source': 'mobile',
      },
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );
  }
}
