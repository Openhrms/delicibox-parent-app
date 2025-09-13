import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class StaffHome extends StatelessWidget {
  final AppUser user;
  const StaffHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final tiles = <_RoleTile>[
      _RoleTile('Executive', Icons.dashboard_customize_outlined, '/staff/executive'),
      _RoleTile('Super Admin', Icons.security_outlined, '/staff/super-admin'),
      _RoleTile('Store Incharge', Icons.storefront_outlined, '/staff/store'),
      _RoleTile('Helpdesk', Icons.support_agent_outlined, '/staff/helpdesk'),
      _RoleTile('Support', Icons.headset_mic_outlined, '/staff/support'),
      _RoleTile('Finance Executive', Icons.payments_outlined, '/staff/finance'),
      _RoleTile('Admin Executive', Icons.admin_panel_settings_outlined, '/staff/admin'),
      _RoleTile('Marketing Executive', Icons.campaign_outlined, '/staff/marketing'),
      _RoleTile('Management', Icons.app_registration_outlined, '/staff/management'),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _hero(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _colsFor(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: tiles.length,
              itemBuilder: (_, i) => _RoleCard(t: tiles[i]),
            ),
          ),
        ],
      ),
    );
  }

  int _colsFor(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 420) return 2;
    if (w < 800) return 3;
    return 4;
  }

  SliverAppBar _hero() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      flexibleSpace: const FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFAD1457), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      title: const Text('Staff Console'),
    );
  }
}

class _RoleTile {
  final String label;
  final IconData icon;
  final String route;
  _RoleTile(this.label, this.icon, this.route);
}

class _RoleCard extends StatefulWidget {
  final _RoleTile t;
  const _RoleCard({required this.t});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => _StubScreen(title: widget.t.label),
        ));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_down ? .985 : 1),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.t.icon, size: 28),
            const SizedBox(height: 10),
            Text(widget.t.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Coming soon…')),
    );
  }
}
