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

  test('iOS warm neighbor preload is scheduled before the page becomes active',
      () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();
    final shortUiSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_ui_part.dart',
    ).readAsString();

    expect(
      shortViewSource,
      contains('void _ensureWarmNeighborAdapterAfterBuild('),
    );
    expect(
      shortViewSource,
      contains('defaultTargetPlatform != TargetPlatform.iOS'),
    );
    expect(
      shortViewSource,
      contains(
        "_segmentCacheRuntimeService.ensureMinimumReadySegments(\n"
        "            neighborDocId,\n"
        "            minimumSegmentCount: StartupPreloadPolicy.neighborReadySegments,",
      ),
    );
    expect(
      shortViewSource,
      contains(
          'await controller.prepareNeighborAdapter(activePage, neighborPage);'),
    );
    expect(
      shortUiSource,
      contains('_ensureWarmNeighborAdapterAfterBuild(currentPage, idx);'),
    );
  });

  test('manual short swipe clears stale auto-advance queue', () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();

    expect(
      shortViewSource,
      contains('final isAutoAdvance = _pendingAutoAdvancePage == page;'),
    );
    expect(
      shortViewSource,
      contains(
        '} else if (_pendingAutoAdvancePage != null) {\n'
        '      _pendingAutoAdvancePage = null;\n'
        '      _isTransitioning = false;',
      ),
    );
  });

  test('short exclusive audio guard skips duplicate active adapter instances',
      () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();

    expect(
      shortViewSource,
      contains('final activeAdapter = controller.cache[activePage];'),
    );
    expect(
      shortViewSource,
      contains('identical(vc, activeAdapter)'),
    );
  });

  test('iOS warm short neighbors stay mounted without explicit pause',
      () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();
    final audioFocusSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Core/Services/audio_focus_coordinator_runtime_part.dart',
    ).readAsString();

    expect(shortViewSource, contains('final isWarmNeighbor ='));
    expect(
      shortViewSource,
      contains('defaultTargetPlatform == TargetPlatform.iOS && isWarmNeighbor'),
    );
    expect(audioFocusSource, contains('p.preferWarmPoolPause'));
    expect(audioFocusSource, contains('!p.value.isPlaying'));
    expect(audioFocusSource, contains('await p.setVolume(0.0);'));
  });

  test('iOS short player requests stable native startup buffer', () async {
    final shortUiSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_ui_part.dart',
    ).readAsString();
    final hlsPlayerSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/hls_player/hls_player.dart',
    ).readAsString();
    final nativePlayerSource = await File(
      '/Users/turqapp/Desktop/TurqApp/ios/Runner/HLSPlayerView.swift',
    ).readAsString();

    expect(shortUiSource, contains('preferStableStartupBuffer:'));
    expect(hlsPlayerSource, contains('preferStableStartupBuffer'));
    expect(
        nativePlayerSource, contains('preferStableStartupBuffer ? 10.0 : 6.0'));
    expect(
      nativePlayerSource,
      contains(
          'player?.automaticallyWaitsToMinimizeStalling = preferStableStartupBuffer'),
    );
  });

  test('iOS short ownership handoff skips pending play queue after startup',
      () async {
    final shortViewSource = await File(
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
    ).readAsString();

    expect(
      shortViewSource,
      contains('final shouldUseDirectOwnershipRequest ='),
    );
    expect(
      shortViewSource,
      contains('defaultTargetPlatform == TargetPlatform.iOS'),
    );
    expect(
      shortViewSource,
      contains('_playbackRuntimeService.requestPlay('),
    );
    expect(
      shortViewSource,
      contains('HLSAdapterPlaybackHandle(adapter)'),
    );
  });
}
