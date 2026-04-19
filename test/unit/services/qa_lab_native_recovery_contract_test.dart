import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native buffer stall finding is skipped after playback has recovered', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Core/Services/qa_lab_recorder_runtime_part.dart',
    ).readAsString();

    expect(
      source,
      contains('hasMeaningfulPlaybackExpectation &&\n        !hasRecoveredPlaybackAtSample'),
    );
  });
}
