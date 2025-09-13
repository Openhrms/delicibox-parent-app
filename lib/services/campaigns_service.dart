import 'package:flutter_riverpod/flutter_riverpod.dart';

class Campaign {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  const Campaign({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.active = true,
  });
}

final donationCampaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  // TODO: If/when Firebase is wired, read from Firestore here.
  final now = DateTime.now();
  final m = DateTime(now.year, now.month, 1);
  return [
    Campaign(
      id: 'sankranthi',
      title: 'Sankranthi Community Drive',
      startDate: DateTime(m.year, 1, 10),
      endDate:   DateTime(m.year, 1, 16),
    ),
    Campaign(
      id: 'dussehra',
      title: 'Dussehra Special Donation',
      startDate: DateTime(m.year, 10, 10),
      endDate:   DateTime(m.year, 10, 14),
    ),
    Campaign(
      id: 'weekend',
      title: 'Weekend Distribution',
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
    ),
  ];
});
