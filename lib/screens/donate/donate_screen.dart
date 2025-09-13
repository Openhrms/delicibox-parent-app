import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/session_user.dart';

class DonationsScreen extends ConsumerWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uAsync = ref.watch(sessionUserProvider);
    return uAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (u) {
        if (u == null) return const Scaffold(body: Center(child: Text('Please login')));
        final dio = Dio(BaseOptions(baseUrl: const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080')));
        return Scaffold(
          appBar: AppBar(title: const Text('Donations')),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: () async {
              final r = await dio.get('/api/v1/users/${u.uid}/donations');
              final list = (r.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
              return list;
            }(),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                if (snap.hasError) return Center(child: Text('Failed to load'));
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) return const Center(child: Text('No donations yet.'));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final m = items[i];
                  final when = (m['date'] ?? '').toString();
                  final reason = (m['reason'] ?? 'Donated').toString();
                  final boxes = (m['boxes'] ?? 1).toString();
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.volunteer_activism_outlined)),
                    title: Text(reason),
                    subtitle: Text(when),
                    trailing: Text('× $boxes'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}


