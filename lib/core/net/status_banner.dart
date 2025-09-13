import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

class NetStatusBanner extends ConsumerWidget {
  const NetStatusBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNet = ref.watch(internetReachableProvider);
    if (hasNet) return const SizedBox.shrink();
    return Material(
      color: Colors.red.shade50,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            const Icon(Icons.wifi_off, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text('No internet connection', style: TextStyle(color: Colors.red.shade700)),
          ]),
        ),
      ),
    );
  }
}
