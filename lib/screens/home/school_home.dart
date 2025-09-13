import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../widgets/section.dart';
import '../../widgets/stat_chip.dart';

class SchoolHome extends StatelessWidget {
  final AppUser user;
  const SchoolHome({super.key, required this.user});

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
                StatChip(label: 'Students', value: '920', icon: Icons.school_outlined, color: Colors.green),
                StatChip(label: 'Active subscriptions', value: '870', icon: Icons.verified_outlined, color: Colors.teal),
                StatChip(label: 'Boxes today', value: '840', icon: Icons.lunch_dining, color: Colors.brown),
              ]),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Actions'),
              _tile(context, Icons.upload_file_outlined, 'Import class list', 'CSV/Excel support'),
              _tile(context, Icons.group_add_outlined, 'Assign plans', 'Bulk assign per class'),
              _tile(context, Icons.analytics_outlined, 'Attendance & Pauses', 'Per class / per student'),
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
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      title: const Text('School Dashboard'),
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
