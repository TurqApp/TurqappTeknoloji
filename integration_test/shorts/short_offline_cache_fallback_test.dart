import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';
import '../core/helpers/transient_error_policy.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Short falls back to fully cached offline metadata when network is unavailable',
    (tester) async {
      final originalOnError = installTransientFlutterErrorPolicy();
      try {
        await SmokeArtifactCollector.runScenario(
          'short_offline_cache_fallback',
          tester,
          () async {
            await launchTurqApp(tester);

            final userId = CurrentUserService.instance.effectiveUserId.trim();
            expect(userId, isNotEmpty);

            final cacheManager = SegmentCacheManager.ensure();
            await cacheManager.init();
            await cacheManager.clearAllCache();

            final cachedPost = _buildOfflineShortPost();
            cacheManager.cachePostCards(<PostsModel>[cachedPost]);
            cacheManager.updateEntryMeta(
              cachedPost.docID,
              cachedPost.playbackUrl,
              1,
            );
            await cacheManager.writeSegment(
              cachedPost.docID,
              '720p/segment_0.ts',
              Uint8List.fromList(<int>[1, 2, 3, 4]),
            );

            final network = NetworkAwarenessService.ensure();
            network.debugSetNetworkOverride(NetworkType.none);
            addTearDown(() {
              network.debugSetNetworkOverride(null);
            });

            await pressItKey(
              tester,
              IntegrationTestKeys.navShort,
            );
            await pumpUntilVisible(
              tester,
              byItKey(IntegrationTestKeys.screenShort),
            );
            await tester.pump(const Duration(seconds: 2));

            expectSurfaceRegistered('short');
            final shortSnapshot = readSurfaceProbe('short');
            final count = (shortSnapshot['count'] as num?)?.toInt() ?? 0;
            final docIds =
                (shortSnapshot['docIds'] as List<dynamic>? ?? const [])
                    .map((item) => item?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(growable: false);

            expect(count, greaterThan(0));
            expect(docIds, contains(cachedPost.docID));
          },
        );
      } finally {
        NetworkAwarenessService.maybeFind()?.debugSetNetworkOverride(null);
        restoreTransientFlutterErrorPolicy(originalOnError);
      }
    },
    skip: !kRunIntegrationSmoke,
  );
}

PostsModel _buildOfflineShortPost() {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 9 / 16,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: 'it_offline_cached_short_1',
    flood: false,
    floodCount: 1,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: 'Offline cached short fallback',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
    timeStamp: nowMs,
    userID: 'it_offline_badge_author',
    authorNickname: 'offline_badge_author',
    authorDisplayName: 'Offline Badge Author',
    authorAvatarUrl: '',
    rozet: 'mavi',
    video: '',
    hlsMasterUrl:
        'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    hlsStatus: 'ready',
    hlsUpdatedAt: nowMs,
    yorum: true,
  );
}
