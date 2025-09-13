import 'package:flutter/material.dart';
class InvoicesTab extends StatelessWidget {
  final String role;
  const InvoicesTab({super.key, required this.role});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$role invoices', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...List.generate(5, (i) => Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text('Invoice #INV-2025-${1000 + i}'),
            subtitle: const Text('Sep 2025 • ₹ 2,499.00'),
            trailing: const Icon(Icons.cloud_download_outlined),
            onTap: () {},
          ),
        ))
      ],
    );
  }
}
