import 'dart:async';
import 'package:flutter/material.dart';

class AsyncGuard extends StatelessWidget {
  final Future<void> future;
  final Widget child;                   // when success
  final Duration timeout;
  final String loadingText;
  final VoidCallback? onTimeoutRetry;

  const AsyncGuard({
    super.key,
    required this.future,
    required this.child,
    this.timeout = const Duration(seconds: 12),
    this.loadingText = 'Loading…',
    this.onTimeoutRetry,
  });

  @override
  Widget build(BuildContext context) {
    final wait = Future.any([
      future,
      Future.delayed(timeout, () => throw _TimeoutMarker()),
    ]);
    return FutureBuilder(
      future: wait,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _Loading(text: loadingText);
        }
        if (snapshot.hasError) {
          if (snapshot.error is _TimeoutMarker) {
            return _Timeout(onRetry: onTimeoutRetry);
          }
          return _ErrorWidget(err: snapshot.error.toString(), onRetry: onTimeoutRetry);
        }
        return child;
      },
    );
  }
}

class _TimeoutMarker {}

class _Loading extends StatelessWidget {
  final String text;
  const _Loading({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        Text(text),
      ]),
    );
  }
}

class _Timeout extends StatelessWidget {
  final VoidCallback? onRetry;
  const _Timeout({this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.hourglass_empty, size: 36),
        const SizedBox(height: 8),
        const Text('Taking too long…'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String err;
  final VoidCallback? onRetry;
  const _ErrorWidget({required this.err, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 36, color: Colors.deepOrange),
        const SizedBox(height: 8),
        Text(err, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        if (onRetry != null) ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
