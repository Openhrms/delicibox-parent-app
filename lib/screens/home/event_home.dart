import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../widgets/section.dart';
import '../../widgets/stat_chip.dart';

class EventHome extends StatelessWidget {
  final AppUser user;
  const EventHome({super.key, required this.user});

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
                StatChip(label: 'Upcoming events', value: '3', icon: Icons.event_available_outlined, color: Colors.orange),
                StatChip(label: 'Expected attendees', value: '780', icon: Icons.confirmation_num_outlined, color: Colors.deepOrange),
                StatChip(label: 'Boxes planned', value: '800', icon: Icons.lunch_dining, color: Colors.brown),
              ]),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Actions'),
              _tile(context, Icons.add_circle_outline, 'Create new event', 'Date, venue, boxes per attendee'),
              _tile(context, Icons.route_outlined, 'Delivery route plan', 'Drop points, slots, drivers'),
              _tile(context, Icons.receipt_long_outlined, 'Invoices', 'Per-event statements'),
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
              colors: [Color(0xFFFF7043), Color(0xFFFFA270)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      title: const Text('Event Dashboard'),
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
