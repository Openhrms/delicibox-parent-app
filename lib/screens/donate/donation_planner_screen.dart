import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/campaigns_service.dart';
import '../../shared/effects.dart';
import '../../shared/reason_picker.dart';
import '../../shared/reason_theme.dart';
import '../calendar/calendar_state.dart';

class DonationPlannerScreen extends ConsumerStatefulWidget {
  const DonationPlannerScreen({super.key});
  @override
  ConsumerState<DonationPlannerScreen> createState() => _DonationPlannerScreenState();
}

class _DonationPlannerScreenState extends ConsumerState<DonationPlannerScreen> {
  ReasonVisuals? _fx;

  static const donateReasons = <String>[
    'Birthday gift','Anniversary','Festival giving','In memory','Helping others','Other'
  ];

  @override
  Widget build(BuildContext context) {
    final cal = ref.watch(calendarProvider);
    final campaigns = ref.watch(donationCampaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan DeliciBoxes')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('My Delici Boxes'),
                  subtitle: const Text('Credits from past pauses (current academic year)'),
                  trailing: Text('${cal.myBoxes}', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              const SizedBox(height: 12),
              Text('Ops Campaigns', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              campaigns.when(
                data: (list) => Column(
                  children: [
                    for (final c in list)
                      Card(
                        child: ListTile(
                          title: Text(c.title),
                          subtitle: Text('${c.startDate.toLocal().toString().substring(0,10)} → ${c.endDate.toLocal().toString().substring(0,10)}'),
                          trailing: ElevatedButton(
                            onPressed: cal.myBoxes == 0 ? null : () => _allocateCampaign(context, c.id, c.title),
                            child: const Text('Donate'),
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                error: (_, __) => const Text('Couldn’t load campaigns (using local defaults).'),
              ),
              const SizedBox(height: 12),
              Text('Use for next month (prorate)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Adjust next bill with DeliciBoxes'),
                  subtitle: const Text('We’ll reduce your payable amount based on your credits.'),
                  trailing: ElevatedButton(
                    onPressed: cal.myBoxes == 0 ? null : () => _allocateUsage(context),
                    child: const Text('Use'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Planned allocations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (cal.plans.isEmpty)
                const ListTile(title: Text('No allocations yet')),
              for (final p in cal.plans)
                Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                      'On ${p.date.toLocal().toString().substring(0,10)} • ${p.boxes} box(es) • '
                      '${p.kind == AllocationKind.donation ? (p.isCampaign ? "Donation (Campaign)" : "Donation (Personal)") : "Usage (Prorate)"}'
                      '${p.reason != null ? " • ${p.reason}" : ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(calendarProvider.notifier).removePlan(p.id);
                        showNiceSnack(context, 'Removed: ${p.title}', icon: Icons.delete_outline, color: Colors.blueGrey);
                      },
                    ),
                  ),
                ),
            ],
          ),
          SmallConfetti(play: _fx != null, colors: _fx?.confetti),
          if (_fx != null) EmojiBurst(play: true, emoji: _fx!.emoji),
        ],
      ),
    );
  }

  Future<void> _allocateCampaign(BuildContext context, String id, String title) async {
    final boxBal = ref.read(calendarProvider).myBoxes;
    if (boxBal <= 0) return;

    int qty = min(3, boxBal);
    final okQty = await showDialog<bool>(
      context: context,
      builder: (_) => _QtyDialog(title: 'How many boxes for "$title"?', max: boxBal, initial: qty),
    );
    if (okQty != true) return;

    final reason = await showReasonSheet(
      context: context,
      title: 'Why donate these boxes?',
      reasons: donateReasons,
    );
    if (reason == null) return;
    final visuals = visualsFor(reason.split(' – ').first, context);

    final now = DateTime.now();
    final success = await ref.read(calendarProvider.notifier).allocateFromCredits(
          id: 'don-${DateTime.now().millisecondsSinceEpoch}-$id',
          title: title,
          date: DateTime(now.year, now.month, now.day),
          boxes: qty,
          isCampaign: true,
          kind: AllocationKind.donation,
          reason: reason,
        );
    if (success) {
      setState(()=>_fx = visuals);
      showNiceSnack(context, 'Donated $qty box(es): $reason', icon: visuals.icon, color: visuals.snackColor);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(()=>_fx = null);
    }
  }

  Future<void> _allocateUsage(BuildContext context) async {
    final boxBal = ref.read(calendarProvider).myBoxes;
    if (boxBal <= 0) return;

    int qty = min(5, boxBal);
    final okQty = await showDialog<bool>(
      context: context,
      builder: (_) => _QtyDialog(title: 'How many boxes to use for proration?', max: boxBal, initial: qty),
    );
    if (okQty != true) return;

    final reason = await showReasonSheet(
      context: context,
      title: 'Reason for using DeliciBoxes (optional)',
      reasons: const ['Used next month','Schedule change','Trial'],
    );

    // Visuals for proration (include smallIcon to satisfy constructor)
    final visuals = const ReasonVisuals(
      confetti: [Color(0xFF66BB6A), Color(0xFF43A047), Color(0xFFA5D6A7)],
      snackColor: Color(0xFF43A047),
      icon: Icons.attach_money,
      smallIcon: Icons.attach_money,
      emoji: '💸',
    );

    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final success = await ref.read(calendarProvider.notifier).allocateFromCredits(
          id: 'use-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Next month bill adjustment',
          date: nextMonth,
          boxes: qty,
          isCampaign: false,
          kind: AllocationKind.usage,
          reason: reason,
        );
    if (success) {
      setState(()=>_fx = visuals);
      showNiceSnack(context, 'Will reduce next bill by $qty box(es)', icon: visuals.icon, color: visuals.snackColor);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(()=>_fx = null);
    }
  }
}

class _QtyDialog extends StatefulWidget {
  final String title; final int max; final int initial;
  const _QtyDialog({required this.title, required this.max, required this.initial});
  @override State<_QtyDialog> createState() => _QtyDialogState();
}
class _QtyDialogState extends State<_QtyDialog> {
  late int qty = widget.initial;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        children: [
          Expanded(child: Slider(min: 1, max: widget.max.toDouble(), value: qty.toDouble(), divisions: (widget.max-1) <= 0 ? 1 : widget.max-1, onChanged: (v)=>setState(()=>qty=v.round()))),
          const SizedBox(width: 8), Text('$qty'),
        ],
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancel')),
        ElevatedButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Confirm')),
      ],
    );
  }
}
