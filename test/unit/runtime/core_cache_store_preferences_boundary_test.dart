import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core cache stores use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/job_saved_store.dart',
      'lib/Core/Services/slider_cache_service.dart',
      'lib/Core/Services/CacheFirst/startup_snapshot_shard_store.dart',
      'lib/Core/Services/CacheFirst/startup_snapshot_manifest_store.dart',
      'lib/Core/Services/CacheFirst/shared_prefs_scoped_snapshot_store.dart',
      'lib/Core/Services/error_handling_service_library.dart',
      'lib/Core/Services/error_handling_service_history_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (!source.contains('SharedPreferences.getInstance')) continue;
      violations.add(path);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Core cache stores should use LocalPreferenceRepository.',
    );
  });
}
