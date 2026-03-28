import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/models.dart';
import 'package:turqappv2/Core/Services/playback_handle.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/PlaybackRuntime/playback_cache_runtime_service.dart';

void main() {
  test('playback runtime service preserves exclusive lifecycle semantics',
      () async {
    final manager = VideoStateManager();
    final service = PlaybackRuntimeService(managerProvider: () => manager);
    final handleA = _FakePlaybackHandle();
    final handleB = _FakePlaybackHandle();

    service.registerPlaybackHandle('doc-a', handleA);
    service.registerPlaybackHandle('doc-b', handleB);

    service.enterExclusiveMode('doc-a');
    expect(service.currentPlayingDocId, 'doc-a');
    await Future<void>.delayed(const Duration(milliseconds: 170));
    expect(handleA.playCount, 1);
    expect(handleB.pauseCount, greaterThanOrEqualTo(1));

    service.updateExclusiveModeDoc('doc-b');
    expect(service.currentPlayingDocId, 'doc-b');
    await Future<void>.delayed(const Duration(milliseconds: 170));
    expect(handleA.pauseCount, greaterThanOrEqualTo(1));
    expect(handleB.playCount, 1);

    service.pauseAll(force: true);
    expect(service.currentPlayingDocId, isNull);
  });

  test('segment cache runtime service centralizes hot lifecycle helpers', () {
    final entries = <String, VideoCacheEntry>{
      'doc-a': VideoCacheEntry(
        docID: 'doc-a',
        masterPlaylistUrl: 'https://example.com/a.m3u8',
        segments: <String, CachedSegment>{
          's1': CachedSegment(
            segmentUri: 's1.ts',
            diskPath: '/tmp/a-1.ts',
            sizeBytes: 10,
            cachedAt: DateTime.utc(2026, 3, 28),
          ),
          's2': CachedSegment(
            segmentUri: 's2.ts',
            diskPath: '/tmp/a-2.ts',
            sizeBytes: 10,
            cachedAt: DateTime.utc(2026, 3, 28),
          ),
        },
      ),
    };
    final marked = <String>[];
    final touched = <String>[];
    final progressUpdates = <String, double>{};
    final service = SegmentCacheRuntimeService(
      entryReader: (docId) => entries[docId],
      markPlayingAction: marked.add,
      touchEntryAction: touched.add,
      updateWatchProgressAction: (docId, progress) {
        progressUpdates[docId] = progress;
      },
    );

    expect(service.cachedSegmentCount('doc-a'), 2);
    expect(service.hasReadySegment('doc-a'), isTrue);
    expect(service.hasReadySegment('missing'), isFalse);

    service.markPlayingAndTouchRecent(
      const <String>['doc-a', 'doc-b', 'doc-c', 'doc-d'],
      2,
      lookBehind: 2,
    );
    service.updateWatchProgress('doc-c', 0.6);

    expect(marked, <String>['doc-c']);
    expect(touched, <String>['doc-b', 'doc-a']);
    expect(progressUpdates['doc-c'], 0.6);
  });

  test('hot playback sources delegate through runtime boundary services',
      () async {
    final playbackLibraryFiles = <String>[
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Story/StoryViewer/story_viewer.dart',
    ];
    final playbackAndCacheLibraryFiles = <String>[
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view.dart',
    ];
    final boundaryFiles = <String>{
      ...playbackLibraryFiles,
      ...playbackAndCacheLibraryFiles,
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_playback_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_media_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_quote_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content_media_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_helpers_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_playback_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_ui_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_controller_bootstrap_part.dart',
      '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/single_short_view_controller_sync_part.dart',
    }.toList(growable: false);

    for (final path in playbackLibraryFiles) {
      final source = await File(path).readAsString();
      expect(source, contains('PlaybackRuntimeService'));
    }

    for (final path in playbackAndCacheLibraryFiles) {
      final source = await File(path).readAsString();
      expect(source, contains('SegmentCacheRuntimeService'));
    }

    for (final path in boundaryFiles) {
      final source = await File(path).readAsString();
      expect(source, isNot(contains('VideoStateManager.instance')));
      expect(source, isNot(contains('SegmentCacheManager.maybeFind')));
      expect(source, isNot(contains('maybeFindVideoStateManager')));
    }
  });
}

class _FakePlaybackHandle implements PlaybackHandle {
  @override
  Duration duration = const Duration(seconds: 30);

  @override
  bool isInitialized = true;

  @override
  bool isPlaying = false;

  @override
  Duration position = Duration.zero;

  int pauseCount = 0;
  int playCount = 0;
  int seekCount = 0;
  int setVolumeCount = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {
    pauseCount++;
    isPlaying = false;
  }

  @override
  Future<void> play() async {
    playCount++;
    isPlaying = true;
  }

  @override
  Future<void> seekTo(Duration nextPosition) async {
    seekCount++;
    position = nextPosition;
  }

  @override
  Future<void> setVolume(double volume) async {
    setVolumeCount++;
  }
}
