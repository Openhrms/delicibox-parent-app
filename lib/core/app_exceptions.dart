import '../models/user_type.dart';

enum AppErrorType {
  network,         // no internet / DNS
  timeout,         // request too slow
  server,          // 5xx
  notFound,        // 404 / missing
  unauthorized,    // 401
  forbidden,       // 403
  inactive,        // user not active
  invalid,         // 400 / validation
  conflict,        // 409
  unknown,         // fallback
}

class AppException implements Exception {
  final AppErrorType type;
  final String? detail; // raw technical detail (logging)
  final int? status;
  const AppException(this.type, {this.detail, this.status});

  /// Polite message for humans. Tuned by user type when helpful.
  String messageFor(UserType t) {
    switch (type) {
      case AppErrorType.network:
        return 'No internet connection. Please check your network and try again.';
      case AppErrorType.timeout:
        return 'This is taking longer than usual. Please retry in a moment.';
      case AppErrorType.server:
        return 'Server is busy right now. We’re on it—please try again shortly.';
      case AppErrorType.notFound:
        return 'We couldn’t find that. It might have been moved.';
      case AppErrorType.unauthorized:
        return 'Your session expired. Please sign in again.';
      case AppErrorType.forbidden:
        return 'You don’t have access to this feature.';
      case AppErrorType.inactive:
        return (t == UserType.parent)
            ? 'Your account is not active. Please renew your plan or contact school support.'
            : 'This account is not active. Please contact your administrator.';
      case AppErrorType.invalid:
        return 'Please review the details and try again.';
      case AppErrorType.conflict:
        return 'This action conflicts with an existing record.';
      case AppErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
