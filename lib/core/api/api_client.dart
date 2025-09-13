import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retry/retry.dart';
import '../app_exceptions.dart';
import 'token_service_bridge.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    sendTimeout: const Duration(seconds: 12),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await ref.read(tokenServiceProvider).getValidAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401) {
        final token = await ref.read(tokenServiceProvider).getValidAccessToken();
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final clone = await dio.fetch(err.requestOptions);
          return handler.resolve(clone);
        }
      }
      handler.next(err);
    },
  ));

  return dio;
});

Future<T> safeCall<T>(Ref ref, Future<T> Function() call) async {
  try {
    return await retry(
      () async => await call(),
      retryIf: (e) =>
          e is DioException &&
          (e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.connectionTimeout),
      maxAttempts: 3,
      delayFactor: const Duration(milliseconds: 500),
    );
  } on DioException catch (e) {
    throw _mapDio(e);
  } on SocketException {
    throw AppException(AppErrorType.network);
  } on AppException {
    rethrow;
  } catch (_) {
    throw AppException(AppErrorType.unknown);
  }
}

AppException _mapDio(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return AppException(AppErrorType.timeout);
  }
  final code = e.response?.statusCode ?? 0;
  if (code >= 500) return AppException(AppErrorType.server, status: code);
  if (code == 401) return AppException(AppErrorType.unauthorized, status: code);
  if (code == 403) return AppException(AppErrorType.forbidden, status: code);
  if (code == 404) return AppException(AppErrorType.notFound, status: code);
  if (code == 409) return AppException(AppErrorType.conflict, status: code);
  if (code >= 400 && code < 500) {
    return AppException(AppErrorType.invalid, status: code, detail: e.response?.data?.toString());
  }
  return AppException(AppErrorType.unknown, detail: e.message);
}
