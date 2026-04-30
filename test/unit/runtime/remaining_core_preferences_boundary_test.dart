import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remaining core helpers use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/story_music_library_service.dart',
      'lib/Core/Services/story_music_library_service_fetch_part.dart',
      'lib/Core/Services/gif_library_service.dart',
      'lib/Core/Helpers/UnreadMessagesController/unread_messages_controller_library.dart',
      'lib/Core/Helpers/UnreadMessagesController/unread_messages_controller_sync_part.dart',
      'lib/Core/Services/AppPolicy/surface_policy_override_service.dart',
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
      reason: 'Core helpers should use LocalPreferenceRepository.',
    );
  });
}
