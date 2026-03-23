part of 'notification_settings_view.dart';

extension _NotificationSettingsViewDataPart on _NotificationSettingsViewState {
  Future<void> _load() async {
    final prefs =
        await NotificationPreferencesService.getCurrentUserPreferences();
    if (!mounted) return;
    _updateViewState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    _writePath(next, path, value);
    _updateViewState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }

  void _writePath(Map<String, dynamic> source, String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> current = source;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final next = current[key];
      if (next is Map<String, dynamic>) {
        current = next;
      } else if (next is Map) {
        current = Map<String, dynamic>.from(next);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
  }

  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }
}
