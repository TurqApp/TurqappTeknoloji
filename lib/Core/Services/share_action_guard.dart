import 'dart:async';

class ShareActionGuard {
  static bool _isSharing = false;
  static int _suppressionDepth = 0;
  static const Object _zoneKey = Object();
  static const Duration _cooldown = Duration(milliseconds: 1200);

  static bool get isSuppressingUnderlyingTouches =>
      _isSharing || _suppressionDepth > 0;

  static Future<T?> suppressUnderlyingTouchesWhile<T>(
    Future<T?> Function() action,
  ) async {
    _suppressionDepth++;
    try {
      return await action();
    } finally {
      _suppressionDepth--;
    }
  }

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
