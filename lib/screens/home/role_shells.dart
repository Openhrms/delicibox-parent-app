import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../widgets/home_scaffold.dart';

// First-tab dashboards (already created in your project)
import 'parent_home.dart';
import 'corporate_home.dart';
import 'event_home.dart';
import 'general_home.dart';
import 'school_home.dart';
import 'staff_home.dart';

// Common tabs
import '../tabs/calendar_tab.dart';
import '../tabs/donate_tab.dart';
import '../tabs/invoices_tab.dart';
import '../tabs/profile_tab.dart';

class ParentShell extends ConsumerWidget {
  final AppUser user;
  const ParentShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'DeliciBox',
      pages: [
        ParentHome(user: user),
        const ParentCalendarTab(),
        const ParentDonateTab(),
        const InvoicesTab(role: 'Parent'),
        const ProfileTab(role: 'Parent'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'),
        NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), label: 'Donate'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Invoices'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class CorporateShell extends ConsumerWidget {
  final AppUser user;
  const CorporateShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'Corporate',
      pages: [
        CorporateHome(user: user),
        const InvoicesTab(role: 'Corporate'),
        const ProfileTab(role: 'Corporate'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Invoices'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class EventShell extends ConsumerWidget {
  final AppUser user;
  const EventShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'Event',
      pages: [
        EventHome(user: user),
        const InvoicesTab(role: 'Event'),
        const ProfileTab(role: 'Event'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Invoices'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class GeneralShell extends ConsumerWidget {
  final AppUser user;
  const GeneralShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'My DeliciBox',
      pages: [
        GeneralHome(user: user),
        const InvoicesTab(role: 'General'),
        const ProfileTab(role: 'General'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Invoices'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class SchoolShell extends ConsumerWidget {
  final AppUser user;
  const SchoolShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'School',
      pages: [
        SchoolHome(user: user),
        const InvoicesTab(role: 'School'),
        const ProfileTab(role: 'School'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Billing'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class StaffShell extends ConsumerWidget {
  final AppUser user;
  const StaffShell({super.key, required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeScaffold(
      title: 'Staff Console',
      pages: [
        StaffHome(user: user),
        const InvoicesTab(role: 'Staff'),
        const ProfileTab(role: 'Staff'),
      ],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Reports'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
