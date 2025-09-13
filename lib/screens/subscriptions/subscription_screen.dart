import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/session_user.dart';
import '../../services/subscription_service.dart';
import '../../models/plan.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uAsync = ref.watch(sessionUserProvider);
    return uAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (u) {
        if (u == null) return const Scaffold(body: Center(child: Text('Please login')));
        final svc = ref.read(subscriptionServiceProvider);
        return StreamBuilder<Map<String,dynamic>?>(
          stream: svc.watchActiveSub(u.uid),
          builder: (ctx, subSnap) {
            final active = subSnap.data;
            return FutureBuilder<List<Plan>>(
              future: svc.fetchPlansWithFallback(),
              builder: (ctx, planSnap) {
                final plans = planSnap.data ?? const <Plan>[];
                return Scaffold(
                  appBar: AppBar(title: const Text('Subscription')),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (active != null) _activeCard(context, active) else const SizedBox.shrink(),
                      const SizedBox(height: 12),
                      Text('Plans', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...plans.map((p) => _planTile(context, ref, u.uid, p)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _activeCard(BuildContext context, Map<String,dynamic> a) {
    final status = (a['status'] ?? '').toString();
    final plan = (a['planName'] ?? a['planCode'] ?? '').toString();
    final until = (a['currentPeriodEnd'] ?? '').toString();
    final pro = a['prorationFirstInvoice'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current plan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(plan, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Status: $status'),
            if (until.isNotEmpty) Text('Current period ends: $until'),
            if (pro != null) Text('First invoice (prorated): ${pro.toString()}'),
          ],
        ),
      ),
    );
  }

  Widget _planTile(BuildContext context, WidgetRef ref, String uid, Plan p) {
    final svc = ref.read(subscriptionServiceProvider);
    return Card(
      child: ListTile(
        title: Text(p.name),
        subtitle: Text('₹${p.priceMonth} / month • ${p.boxesPerMonth} boxes • Pause ${p.pauseDaysAllowed}/mo'),
        trailing: FilledButton(
          onPressed: () async {
            await svc.startSubscription(uid, p);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription created (pending payment)'),
                  backgroundColor: Colors.green),
              );
            }
            // TODO: handoff to payment gateway here (Razorpay/Stripe) and call markActive() on success
          },
          child: const Text('Choose'),
        ),
      ),
    );
  }
}
