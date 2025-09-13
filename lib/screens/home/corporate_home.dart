import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../widgets/section.dart';
import '../../widgets/stat_chip.dart';

class CorporateHome extends StatelessWidget {
  final AppUser user;
  const CorporateHome({super.key, required this.user});

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
                StatChip(label: 'Active plans', value: '12', icon: Icons.task_alt, color: Colors.indigo),
                StatChip(label: 'Employees', value: '320', icon: Icons.groups_2_outlined, color: Colors.blue),
                StatChip(label: 'Boxes donated', value: '54', icon: Icons.volunteer_activism_outlined, color: Colors.teal),
              ]),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Actions'),
              _tile(context, Icons.upload_file_outlined, 'Bulk enroll employees', 'CSV import with email/phone'),
              _tile(context, Icons.receipt_long_outlined, 'Invoices & Payments', 'Download monthly statements'),
              _tile(context, Icons.analytics_outlined, 'Usage & Pauses', 'Attendance, pauses, donations'),
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
              colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      title: const Text('Corporate Dashboard'),
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
