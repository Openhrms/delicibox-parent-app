import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/effects.dart';
import '../../shared/reason_picker.dart';
import '../../shared/reason_theme.dart';
import '../../shared/child_name.dart';
import 'calendar_state.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int _pulseIndex = -1;
  ReasonVisuals? _fx; // current effect (confetti/emoji)

  // DO NOT include "Other" (picker adds it)
  static const pauseReasons = <String>[
    'Travel/Vacation','Not feeling well','Celebration','Festival','Exams','Family event'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cal = ref.watch(calendarProvider);
    final ctrl = ref.read(calendarProvider.notifier);

    final monthLabel = DateFormat.yMMMM().format(cal.month);
    final first = DateTime(cal.month.year, cal.month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(cal.month.year, cal.month.month);
    final startWeekday = first.weekday;
    final cells = <DateTime?>[];
    for (int i = 1; i < startWeekday; i++) { cells.add(null); }
    for (int d = 1; d <= daysInMonth; d++) { cells.add(DateTime(cal.month.year, cal.month.month, d)); }
    final today = asYMD(DateTime.now());

    final weekdayLabels = const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: ctrl.prevMonth, icon: const Icon(Icons.chevron_left)),
                  Text(monthLabel, style: Theme.of(context).textTheme.titleLarge),
                  IconButton(onPressed: ctrl.nextMonth, icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.pause_circle_filled, size: 18),
                    label: Text('Paused DeliciBoxes: ${ctrl.thisMonthPausedCount}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text('My Delici Boxes: ${cal.myBoxes}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Day names row
              Row(
                children: [
                  for (final w in weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(w,
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: Theme.of(context).textTheme.bodySmall!.color?.withOpacity(.7),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (ctx, i) {
                    final d = cells[i];
                    if (d == null) return const SizedBox.shrink();
                    final isToday = asYMD(d) == today;
                    final paused = cal.pausedDays.contains(asYMD(d));
                    final key = asYMD(d).toIso8601String().substring(0,10);
                    final reason = cal.pauseReasons[key];
                    final reasonBase = reason?.split(' – ').first;
                    final visuals = reasonBase != null ? visualsFor(reasonBase, context) : null;

                    final scale = (_pulseIndex == i) ? 1.10 : (paused ? 1.06 : 1.0);

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        setState(() => _pulseIndex = i);
                        await Future.delayed(const Duration(milliseconds: 140));
                        setState(() => _pulseIndex = -1);

                        if (!paused) {
                          final picked = await showReasonSheet(
                            context: ctx,
                            title: 'Why are you pausing ${DateFormat('d MMM').format(d)}?',
                            reasons: pauseReasons,
                          );
                          if (picked == null) return;

                          final ok = ctrl.setPause(d, paused: true, reason: picked);
                          if (!ok) {
                            showNiceSnack(ctx, 'Pause limit (5) reached', icon: Icons.error_outline, color: Colors.deepOrange);
                            return;
                          }

                          final base = picked.split(' – ').first.toLowerCase();

                          if (base.contains('not feeling')) {
                            // No confetti; show caring message with child name
                            final name = await primaryChildName();
                            showNiceSnack(ctx, 'Take care of your child: $name', icon: Icons.volunteer_activism, color: const Color(0xFF26A69A));
                            setState(()=> _fx = null);
                          } else {
                            final v = visualsFor(base, context);
                            setState(()=> _fx = v.confetti.isEmpty ? null : v);
                            showNiceSnack(ctx, 'Paused ${DateFormat('d MMM').format(d)} • $picked', icon: v.icon, color: v.snackColor);
                            await Future.delayed(const Duration(milliseconds: 900));
                            if (mounted) setState(()=> _fx = null);
                          }
                        } else {
                          final yes = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Resume this day?'),
                              content: Text('Resume ${DateFormat('d MMM').format(d)}?\nReason was: ${reason ?? "—"}'),
                              actions: [
                                TextButton(onPressed: ()=>Navigator.pop(dialogCtx, false), child: const Text('No')),
                                ElevatedButton(onPressed: ()=>Navigator.pop(dialogCtx, true), child: const Text('Yes, resume')),
                              ],
                            ),
                          );
                          if (yes != true) return;
                          ctrl.setPause(d, paused: false);
                          showNiceSnack(ctx, 'Resumed ${DateFormat('d MMM').format(d)}',
                              icon: Icons.play_circle, color: Colors.grey);
                        }
                      },
                      child: AnimatedScale(
                        scale: scale,
                        curve: Curves.easeOutBack,
                        duration: const Duration(milliseconds: 180),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: paused ? Theme.of(context).colorScheme.primary.withOpacity(.18) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                  width: isToday ? 1.6 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(fontWeight: paused ? FontWeight.w700 : FontWeight.w500),
                                ),
                              ),
                            ),
                            if (paused)
                              Positioned(
                                right: 4, top: 4,
                                child: Tooltip(
                                  message: reason ?? 'Paused',
                                  child: Icon(
                                    (visuals?.smallIcon) ?? Icons.pause_circle_filled,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Confetti only when _fx has a palette (i.e., not for "Not feeling well")
          SmallConfetti(play: _fx != null, colors: _fx?.confetti),
        ],
      ),
    );
  }
}
