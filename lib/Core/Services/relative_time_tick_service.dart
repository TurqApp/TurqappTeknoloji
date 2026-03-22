import 'dart:async';

import 'package:get/get.dart';

class RelativeTimeTickService {
  RelativeTimeTickService._() {
    _scheduleAlignedTick();
  }

  static RelativeTimeTickService? _instance;
  static RelativeTimeTickService? maybeFind() => _instance;

  static RelativeTimeTickService ensure() =>
      maybeFind() ?? (_instance = RelativeTimeTickService._());

  final RxInt tick = DateTime.now().millisecondsSinceEpoch.obs;
  Timer? _alignTimer;
  Timer? _minuteTimer;

  void _scheduleAlignedTick() {
    _alignTimer?.cancel();
    _minuteTimer?.cancel();
    _emitTick();

    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    final delay = nextMinute.difference(now);

    _alignTimer = Timer(delay, () {
      _emitTick();
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _emitTick();
      });
    });
  }

  void _emitTick() {
    tick.value = DateTime.now().millisecondsSinceEpoch;
  }
}
