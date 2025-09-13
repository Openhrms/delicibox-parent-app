import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/session.dart';
import '../shared/auth.dart';
import 'auth/login_phone.dart';
import 'calendar/calendar_screen.dart';
import 'donate/donate_screen.dart';

enum AppTab { home, calendar, children, corporate, event, orders, donate, profile }

class TabsScaffold extends ConsumerStatefulWidget {
  const TabsScaffold({super.key});
  @override
  ConsumerState<TabsScaffold> createState() => _TabsScaffoldState();
}

class _TabsScaffoldState extends ConsumerState<TabsScaffold> {
  int _index = 0;

  List<AppTab> _tabsFor(Session s) {
    return [
      AppTab.home,
      if (s.isParent) AppTab.calendar,
      if (s.isParent) AppTab.children,
      if (s.isCorporateEmp) AppTab.corporate,
      if (s.isEventCreator) AppTab.event,
      AppTab.orders,
      AppTab.donate,
      AppTab.profile,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final user = ref.watch(authStateChangesProvider).value;
    final tabs = _tabsFor(session);
    final current = tabs[_index];

    Widget screenFor(AppTab t) {
      switch (t) {
        case AppTab.home:
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Logged in as ${user.phoneNumber ?? user.uid}', textAlign: TextAlign.center),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPhone()),
                  ),
                  child: Text(user == null ? 'Login with Phone (DEV)' : 'Account'),
                ),
              ],
            ),
          );
        case AppTab.calendar:  return const CalendarScreen();
        case AppTab.children:  return const _Stub(title: 'Children');
        case AppTab.corporate: return const _Stub(title: 'Corporate (stub)');
        case AppTab.event:     return const _Stub(title: 'Event (stub)');
        case AppTab.orders:    return const _Stub(title: 'Orders');
        case AppTab.donate:    return const DonateScreen();
        case AppTab.profile:   return const _Stub(title: 'Profile');
      }
    }

    IconData iconFor(AppTab t) {
      switch (t) {
        case AppTab.home: return Icons.home_outlined;
        case AppTab.calendar: return Icons.calendar_month_outlined;
        case AppTab.children: return Icons.family_restroom_outlined;
        case AppTab.corporate: return Icons.work_outline;
        case AppTab.event: return Icons.event_outlined;
        case AppTab.orders: return Icons.receipt_long_outlined;
        case AppTab.donate: return Icons.favorite_border;
        case AppTab.profile: return Icons.person_outline;
      }
    }

    String labelFor(AppTab t) {
      switch (t) {
        case AppTab.home: return 'Home';
        case AppTab.calendar: return 'Calendar';
        case AppTab.children: return 'Children';
        case AppTab.corporate: return 'Corporate';
        case AppTab.event: return 'Event';
        case AppTab.orders: return 'Orders';
        case AppTab.donate: return 'Donate';
        case AppTab.profile: return 'Profile';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(labelFor(current))),
      body: screenFor(current),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(iconFor(t)), label: labelFor(t)),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final s = ref.read(sessionProvider);
          ref.read(sessionProvider.notifier).state = Session(
            isParent: !s.isParent,
            isCorporateEmp: !s.isCorporateEmp,
            isEventCreator: !s.isEventCreator,
          );
        },
        label: const Text('Toggle Roles (dev)'),
        icon: const Icon(Icons.admin_panel_settings_outlined),
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
