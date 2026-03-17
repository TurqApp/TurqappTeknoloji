import 'dart:async';

class ShareActionGuard {
  static bool _isSharing = false;
  static const Object _zoneKey = Object();
  static const Duration _cooldown = Duration(milliseconds: 1200);

  static Future<void> run(Future<void> Function() action) async {
    if (Zone.current[_zoneKey] == true) {
      await action();
      return;
    }
    if (_isSharing) return;
    _isSharing = true;
    try {
      await runZoned(
        () async {
          await action();
        },
        zoneValues: {_zoneKey: true},
      );
      // Share sheet acilirken artis arda gelen tiklari yut.
      await Future<void>.delayed(_cooldown);
    } finally {
      _isSharing = false;
    }
  }
}
