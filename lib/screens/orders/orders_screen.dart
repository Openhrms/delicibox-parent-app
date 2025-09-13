import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/calendar_state.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const double defaultMonthlyPrice = 2400; // ₹
  static const int defaultDeliveriesPerMonth = 22;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cal = ref.watch(calendarProvider);

    // Usage allocations scheduled (reduce next month bill)
    final usage = cal.plans.where((p) => p.kind == AllocationKind.usage).toList();
    final nextMonthBoxes = usage.fold<int>(0, (a, b) => a + b.boxes);

    final price = defaultMonthlyPrice;
    final perBox = price / defaultDeliveriesPerMonth;
    final discount = (nextMonthBoxes * perBox);
    final payable = (price - discount).clamp(0, price);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders & Billing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Your plan'),
              subtitle: const Text('Monthly subscription'),
              trailing: Text('₹${price.toStringAsFixed(0)}'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Planned proration (next month)'),
              subtitle: Text('$nextMonthBoxes DeliciBox credit(s) will be applied'),
              trailing: Text('-₹${discount.toStringAsFixed(0)}'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Estimated payable (next month)'),
              trailing: Text('₹${payable.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: This is an estimate. Final payable depends on actual delivery days and any school holidays configured by Ops.',
          ),
        ],
      ),
    );
  }
}
