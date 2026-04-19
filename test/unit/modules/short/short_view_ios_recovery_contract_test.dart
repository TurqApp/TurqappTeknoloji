import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'iOS short recovery avoids duration-only hard reload during early stalls',
      () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();

    expect(
      source,
      contains(
        'vc.value.position >= const Duration(milliseconds: 2500)',
      ),
    );
    expect(
      source,
      contains(
        'afterPosition >= const Duration(milliseconds: 2500)',
      ),
    );
    expect(
      source,
      contains(
        'value.position >= const Duration(milliseconds: 2500)',
      ),
    );
    expect(
      source,
      isNot(contains('duration > const Duration(seconds: 12)')),
    );
  });

  test('iOS short QA skip path keeps stable frame reporting visible', () async {
    final source = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();

    expect(source, contains('short_page_play_skipped'));
    expect(source, contains("skipReason: 'already_playing'"));
    expect(source, contains('_reportStableShortFrameIfNeeded('));
  });

  test('short telemetry marks first frame on rendered frame, not only playing',
      () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();
    final singleShortSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_helpers_part.dart',
    ).readAsString();

    expect(
      shortViewSource,
      contains(
        'if (!_telemetryFirstFrame && (v.hasRenderedFirstFrame || v.isPlaying))',
      ),
    );
    expect(
      singleShortSource,
      contains(
        'if (!_telemetryFirstFrame &&\n'
        '        (value.hasRenderedFirstFrame || value.isPlaying))',
      ),
    );
  });
}
