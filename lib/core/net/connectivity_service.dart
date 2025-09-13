import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Normalized connectivity stream:
/// - If plugin emits List<ConnectivityResult> (web/new), we use the last.
/// - If it emits ConnectivityResult (older), we pass it through.
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  final raw = Connectivity().onConnectivityChanged;
  // In some versions this is Stream<List<ConnectivityResult>>; map to single value.
  return raw.map((event) {
    if (event is List<ConnectivityResult>) {
      return event.isNotEmpty ? event.last : ConnectivityResult.none;
    } else {
      return event as ConnectivityResult;
    }
  });
});

/// Simple reachability flag (device-level). For server reachability,
/// we will add a ping to the API host later.
final internetReachableProvider = Provider<bool>((ref) {
  final state = ref.watch(connectivityProvider);
  return state.maybeWhen(
    data: (r) => r != ConnectivityResult.none,
    orElse: () => true, // optimistic while loading
  );
});
