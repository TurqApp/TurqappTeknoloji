part of 'notification_settings_view.dart';

extension _NotificationCategoryViewDataPart on _NotificationCategoryViewState {
  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    final segments = path.split('.');
    Map<String, dynamic> current = next;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final nested = current[key];
      if (nested is Map<String, dynamic>) {
        current = nested;
      } else if (nested is Map) {
        current = Map<String, dynamic>.from(nested);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
    setState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }
}
