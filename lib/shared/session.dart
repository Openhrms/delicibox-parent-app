import 'package:flutter_riverpod/flutter_riverpod.dart';

class Session {
  final bool isParent;
  final bool isCorporateEmp;
  final bool isEventCreator;
  const Session({
    this.isParent = true,
    this.isCorporateEmp = false,
    this.isEventCreator = false,
  });
}

final sessionProvider = StateProvider<Session>((_) => const Session(
  isParent: true,
  isCorporateEmp: false,
  isEventCreator: false,
));
