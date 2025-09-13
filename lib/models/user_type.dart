import 'package:flutter/material.dart';

enum UserType { parent, corporate, event, general, school, staff }

String userTypeLabel(UserType t) {
  switch (t) {
    case UserType.parent: return 'Parent';
    case UserType.corporate: return 'Corporate';
    case UserType.event: return 'Event';
    case UserType.general: return 'General';
    case UserType.school: return 'School';
    case UserType.staff: return 'Staff';
  }
}

String userTypeDesc(UserType t) {
  switch (t) {
    case UserType.parent: return 'Manage subscriptions for your child(ren).';
    case UserType.corporate: return 'Manage subscriptions across your company.';
    case UserType.event: return 'Plan DeliciBox for your events and drives.';
    case UserType.general: return 'Subscribe for yourself or family.';
    case UserType.school: return 'School admins managing all students.';
    case UserType.staff: return 'Internal staff operations & reports.';
  }
}

IconData userTypeIcon(UserType t) {
  switch (t) {
    case UserType.parent: return Icons.family_restroom;
    case UserType.corporate: return Icons.apartment;
    case UserType.event: return Icons.event;
    case UserType.general: return Icons.person;
    case UserType.school: return Icons.school;
    case UserType.staff: return Icons.verified_user;
  }
}

Color userTypeColor(UserType t) {
  switch (t) {
    case UserType.parent: return const Color(0xFF6C63FF);
    case UserType.corporate: return const Color(0xFF0EA5E9);
    case UserType.event: return const Color(0xFFF59E0B);
    case UserType.general: return const Color(0xFF10B981);
    case UserType.school: return const Color(0xFF8B5CF6);
    case UserType.staff: return const Color(0xFFEF4444);
  }
}
