import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/user_type.dart';
import '../../widgets/section.dart';
import '../../widgets/stat_chip.dart';

class ParentHome extends StatefulWidget {
  final AppUser user;
  const ParentHome({super.key, required this.user});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  // Demo data (replace with live API later)
  int boxesThisMonth = 22;
  int pausedThisMonth = 2;
  int donatedThisMonth = 1;
  int myDeliciBoxesAY = 7; // summary of not used/donated in current academic year

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6C63FF);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          setState(() {}); // re-fetch later
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _hero(color),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList.list(children: [
                _statRow(color),
                const SizedBox(height: 12),
                _quickActions(color),
                const SizedBox(height: 12),
                _childrenCard(),
                const SizedBox(height: 12),
                _upcomingCard(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _hero(Color color) {
    final name = widget.user.displayName.isNotEmpty ? widget.user.displayName : 'Parent';
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF928CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
            alignment: Alignment.bottomLeft,
            child: Text(
              'Hello, $name 👋',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(Color color) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        StatChip(label: 'This month', value: '$boxesThisMonth boxes', icon: Icons.lunch_dining, color: color),
        StatChip(label: 'Paused', value: '$pausedThisMonth days', icon: Icons.pause_circle_outline, color: Colors.deepPurple),
        StatChip(label: 'Donated', value: '$donatedThisMonth', icon: Icons.volunteer_activism_outlined, color: Colors.teal),
        StatChip(label: 'My DeliciBoxes (AY)', value: '$myDeliciBoxesAY', icon: Icons.inventory_2_outlined, color: Colors.brown),
      ],
    );
  }

  Widget _quickActions(Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _qa(Icons.pause_circle_outline, 'Pause day', () {
              Navigator.pushNamed(context, '/calendar');
            }),
            const SizedBox(width: 12),
            _qa(Icons.volunteer_activism_outlined, 'Donate box', () {
              Navigator.pushNamed(context, '/donate');
            }),
            const SizedBox(width: 12),
            _qa(Icons.receipt_long_outlined, 'Invoices', () {
              Navigator.pushNamed(context, '/invoices');
            }),
          ],
        ),
      ),
    );
  }

  Widget _qa(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _childrenCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'My Children'),
            const SizedBox(height: 8),
            ...List.generate(2, (i) => _kidTile(i)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-child'),
              icon: const Icon(Icons.add),
              label: const Text('Add child'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kidTile(int i) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(child: Text('K${i + 1}')),
      title: Text('Child ${i + 1}'),
      subtitle: const Text('Class: 4'),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {},
      ),
      onTap: () => Navigator.pushNamed(context, '/child/${i + 1}'),
    );
  }

  Widget _upcomingCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Upcoming'),
            const SizedBox(height: 8),
            _upcomingTile(Icons.cake_outlined, 'Birthday treat', 'Donate 3 boxes on Sat'),
            _upcomingTile(Icons.local_florist_outlined, 'Dussehra pause', 'Oct 2–6 • Auto-pause'),
          ],
        ),
      ),
    );
  }

  Widget _upcomingTile(IconData icon, String title, String sub) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
