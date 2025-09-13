import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../widgets/section.dart';
import '../../widgets/stat_chip.dart';

class GeneralHome extends StatelessWidget {
  final AppUser user;
  const GeneralHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _hero(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.list(children: [
              Wrap(spacing: 10, runSpacing: 10, children: const [
                StatChip(label: 'Current plan', value: 'Monthly Std', icon: Icons.workspace_premium_outlined, color: Colors.blueGrey),
                StatChip(label: 'This month', value: '22 boxes', icon: Icons.lunch_dining, color: Colors.blue),
                StatChip(label: 'Donated', value: '4', icon: Icons.volunteer_activism_outlined, color: Colors.teal),
              ]),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Actions'),
              _tile(context, Icons.calendar_month_outlined, 'Pause days', 'Plan vacations / leaves'),
              _tile(context, Icons.volunteer_activism_outlined, 'Donate to society', 'Gift boxes to community'),
              _tile(context, Icons.receipt_long_outlined, 'Invoices', 'Download statements'),
            ]),
          ),
        ],
      ),
    );
  }

  SliverAppBar _hero() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      flexibleSpace: const FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF37474F), Color(0xFF78909C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      title: const Text('My DeliciBox'),
    );
  }

  Widget _tile(BuildContext ctx, IconData i, String t, String s) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(i)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(s),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}
