import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PauseRules {
  static const monthlyPauseAllowance = 5; // still enforce 5 pause days max per month
}

/// Allocation kind: donation or usage (prorate)
enum AllocationKind { donation, usage }

/// Persisted allocation plan (donation or next-month usage)
class AllocationPlan {
  final String id;
  final String title;     // e.g., "Dussehra Drive" or "Next month bill adjustment"
  final DateTime date;    // when to donate/use
  final int boxes;        // number of DeliciBoxes allocated
  final bool isCampaign;  // true only for Ops campaigns
  final String? reason;   // friendly reason text
  final AllocationKind kind;

  AllocationPlan({
    required this.id,
    required this.title,
    required this.date,
    required this.boxes,
    required this.isCampaign,
    required this.kind,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'boxes': boxes,
        'isCampaign': isCampaign,
        'reason': reason,
        'kind': kind.name,
      };

  static AllocationPlan fromJson(Map<String, dynamic> j) => AllocationPlan(
        id: j['id'],
        title: j['title'],
        date: DateTime.parse(j['date']),
        boxes: j['boxes'],
        isCampaign: j['isCampaign'] == true,
        reason: j['reason'],
        kind: _parseKind(j['kind']),
      );

  static AllocationKind _parseKind(dynamic v) {
    if (v is String && v == 'usage') return AllocationKind.usage;
    return AllocationKind.donation;
  }
}

DateTime asYMD(DateTime d) => DateTime(d.year, d.month, d.day);
String monthKey(DateTime m) => 'ym:${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

class CalendarState {
  final DateTime month;                    // first day of visible month
  final Set<DateTime> pausedDays;          // paused days for visible month
  final Map<String, String> pauseReasons;  // 'YYYY-MM-DD' -> reason (visible month)
  final int myBoxes;                       // DeliciBox credits available in academic year
  final List<AllocationPlan> plans;        // planned donations/usages
  final Set<String> closedMonths;          // months already converted into credits

  CalendarState({
    required this.month,
    Set<DateTime>? pausedDays,
    Map<String, String>? pauseReasons,
    this.myBoxes = 0,
    List<AllocationPlan>? plans,
    Set<String>? closedMonths,
  })  : pausedDays = pausedDays ?? <DateTime>{},
        pauseReasons = pauseReasons ?? <String, String>{},
        plans = plans ?? const <AllocationPlan>[],
        closedMonths = closedMonths ?? <String>{};

  CalendarState copyWith({
    DateTime? month,
    Set<DateTime>? pausedDays,
    Map<String, String>? pauseReasons,
    int? myBoxes,
    List<AllocationPlan>? plans,
    Set<String>? closedMonths,
  }) {
    return CalendarState(
      month: month ?? this.month,
      pausedDays: pausedDays ?? this.pausedDays,
      pauseReasons: pauseReasons ?? this.pauseReasons,
      myBoxes: myBoxes ?? this.myBoxes,
      plans: plans ?? this.plans,
      closedMonths: closedMonths ?? this.closedMonths,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(CalendarState(month: DateTime(DateTime.now().year, DateTime.now().month)));

  bool _loaded = false;

  /// Load visible month data + yearly balance + plans, then auto-close last month to credits.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();

    // Load visible month paused+reasons
    await _loadMonth(prefs, state.month);

    // Load credits/plans/closedMonths (yearly)
    final myBoxes = prefs.getInt('myBoxes') ?? 0;
    final closed = (prefs.getStringList('closedMonths') ?? const <String>[]).toSet();
    final plansJson = prefs.getString('allocationPlans');
    final plans = plansJson == null
        ? <AllocationPlan>[]
        : (jsonDecode(plansJson) as List)
            .map((e) => AllocationPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    state = state.copyWith(myBoxes: myBoxes, plans: plans, closedMonths: closed);

    // Auto-close previous month (convert its paused days into credits) once
    await _autoClosePreviousMonthIfNeeded(prefs);
  }

  Future<void> _loadMonth(SharedPreferences prefs, DateTime m) async {
    final key = monthKey(m);
    final pausedJson = prefs.getString('$key:paused');
    Set<DateTime> paused = {};
    if (pausedJson != null) {
      paused = (jsonDecode(pausedJson) as List).map((e) => DateTime.parse(e as String)).toSet();
    }
    final reasonsJson = prefs.getString('$key:pauseReasons');
    Map<String, String> reasons = {};
    if (reasonsJson != null) {
      reasons = Map<String, dynamic>.from(jsonDecode(reasonsJson))
          .map((k, v) => MapEntry(k, v.toString()));
    }
    state = state.copyWith(pausedDays: paused, pauseReasons: reasons);
  }

  Future<void> _saveVisibleMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final key = monthKey(state.month);
    await prefs.setString(
        '$key:paused', jsonEncode(state.pausedDays.map((d) => asYMD(d).toIso8601String()).toList()));
    await prefs.setString('$key:pauseReasons', jsonEncode(state.pauseReasons));
  }

  Future<void> _saveYearly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('myBoxes', state.myBoxes);
    await prefs.setStringList('closedMonths', state.closedMonths.toList());
    await prefs.setString(
      'allocationPlans',
      jsonEncode(state.plans.map((p) => p.toJson()).toList()),
    );
  }

  /// On entering a new month, last month's paused count becomes credits (once).
  Future<void> _autoClosePreviousMonthIfNeeded(SharedPreferences prefs) async {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    final keyPrev = monthKey(prev);
    if (state.closedMonths.contains(keyPrev)) return;

    // read prev-month paused days (if any)
    final pausedJson = prefs.getString('$keyPrev:paused');
    if (pausedJson == null) return;
    final count = (jsonDecode(pausedJson) as List).length;
    if (count <= 0) {
      state = state.copyWith(closedMonths: {...state.closedMonths, keyPrev});
      await _saveYearly();
      return;
    }

    // Add to credits and mark month closed
    state = state.copyWith(
      myBoxes: state.myBoxes + count,
      closedMonths: {...state.closedMonths, keyPrev},
    );
    await _saveYearly();
  }

  void prevMonth() async {
    final m = state.month;
    final next = DateTime(m.year, m.month - 1);
    state = state.copyWith(month: next);
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await _loadMonth(prefs, next);
  }

  void nextMonth() async {
    final m = state.month;
    final next = DateTime(m.year, m.month + 1);
    state = state.copyWith(month: next);
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await _loadMonth(prefs, next);
  }

  int get thisMonthPausedCount =>
      state.pausedDays.where((d) => d.year == state.month.year && d.month == state.month.month).length;

  /// Set paused/unpaused with reason. Returns true if applied.
  bool setPause(DateTime day, {required bool paused, String? reason}) {
    day = asYMD(day);
    if (day.month != state.month.month || day.year != state.month.year) return false;

    final set = {...state.pausedDays};
    final reasons = {...state.pauseReasons};
    final k = asYMD(day).toIso8601String().substring(0, 10);

    if (paused) {
      if (set.contains(day)) return true;
      if (thisMonthPausedCount >= PauseRules.monthlyPauseAllowance) return false;
      set.add(day);
      reasons[k] = reason ?? 'Other';
    } else {
      set.remove(day);
      reasons.remove(k);
    }

    state = state.copyWith(pausedDays: set, pauseReasons: reasons);
    _saveVisibleMonth();
    return true;
  }

  /// Allocate from credits to donation or usage (prorate next month)
  Future<bool> allocateFromCredits({
    required String id,
    required String title,
    required DateTime date,
    required int boxes,
    required bool isCampaign,
    required AllocationKind kind,
    String? reason,
  }) async {
    if (boxes <= 0 || boxes > state.myBoxes) return false;
    final plans = [
      ...state.plans,
      AllocationPlan(
        id: id, title: title, date: asYMD(date),
        boxes: boxes, isCampaign: isCampaign, kind: kind, reason: reason,
      ),
    ];
    state = state.copyWith(myBoxes: state.myBoxes - boxes, plans: plans);
    await _saveYearly();
    return true;
  }

  Future<void> removePlan(String id) async {
    final plans = [...state.plans]..removeWhere((p) => p.id == id);
    state = state.copyWith(plans: plans);
    await _saveYearly();
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) => CalendarNotifier());
