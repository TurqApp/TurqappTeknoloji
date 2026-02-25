class ShareActionGuard {
  static bool _isSharing = false;

  static Future<void> run(Future<void> Function() action) async {
    if (_isSharing) return;
    _isSharing = true;
    try {
      await action();
      // Share sheet açıldıktan hemen sonra çift tetiklemeyi engelle.
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } finally {
      _isSharing = false;
    }
  }
}
