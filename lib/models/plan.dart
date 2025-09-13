class Plan {
  final String id;
  final String code;
  final String name;
  final String currency;
  final num priceMonth;
  final int boxesPerMonth;
  final int pauseDaysAllowed;

  Plan({
    required this.id,
    required this.code,
    required this.name,
    required this.currency,
    required this.priceMonth,
    required this.boxesPerMonth,
    required this.pauseDaysAllowed,
  });

  factory Plan.fromMap(String id, Map<String,dynamic> m) => Plan(
    id: id,
    code: (m['code'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    currency: (m['currency'] ?? 'INR').toString(),
    priceMonth: (m['price_month'] ?? m['priceMonth'] ?? 0) as num,
    boxesPerMonth: (m['boxes_per_month'] ?? m['boxesPerMonth'] ?? 0) as int,
    pauseDaysAllowed: (m['pause_days_allowed'] ?? m['pauseDaysAllowed'] ?? 5) as int,
  );
}
