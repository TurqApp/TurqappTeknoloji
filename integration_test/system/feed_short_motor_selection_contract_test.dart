import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_feed_application_service.dart';
import 'package:turqappv2/Modules/Short/short_feed_application_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feed and short launch motors', () {
    testWidgets(
      'only emit motor-selected cards and keep them newest first',
      (tester) async {
        final anchor = DateTime(2026, 4, 12, 0, 10, 0, 820);
        final anchorMs = anchor.millisecondsSinceEpoch;
        final feedService = AgendaFeedApplicationService(
          nowMsProvider: () => anchorMs,
        );
        final shortService = ShortFeedApplicationService(
          nowMsProvider: () => anchorMs,
        );

        final feedCandidates = <PostsModel>[
          _videoPost('feed-owned-1', DateTime(2026, 4, 11, 23, 54, 0, 810)),
          _videoPost('feed-owned-2', DateTime(2026, 4, 11, 23, 28, 0, 815)),
          _videoPost('feed-owned-3', DateTime(2026, 4, 11, 22, 21, 0, 825)),
          _videoPost('feed-not-owned-a', DateTime(2026, 4, 12, 0, 5, 0, 900)),
          _videoPost('feed-not-owned-b', DateTime(2026, 4, 11, 23, 29, 0, 900)),
          _videoPost('feed-not-owned-c', DateTime(2026, 4, 11, 22, 20, 0, 900)),
        ];
        final feedSelected = feedService.buildStartupPlannerHead(
          liveCandidates: feedCandidates,
          cacheCandidates: const <PostsModel>[],
          targetCount: 10,
        );

        expect(
          feedSelected.map((post) => post.docID).toList(),
          <String>['feed-owned-1', 'feed-owned-2', 'feed-owned-3'],
        );

        final shortCandidates = <PostsModel>[
          _videoPost('short-owned-1', DateTime(2026, 4, 12, 0, 6, 0, 810)),
          _videoPost('short-owned-2', DateTime(2026, 4, 11, 23, 58, 0, 815)),
          _videoPost('short-owned-3', DateTime(2026, 4, 11, 22, 13, 0, 825)),
          _videoPost('short-not-owned-a', DateTime(2026, 4, 12, 0, 5, 0, 900)),
          _videoPost('short-not-owned-b', DateTime(2026, 4, 11, 23, 33, 0, 900)),
          _videoPost('short-not-owned-c', DateTime(2026, 4, 11, 22, 14, 0, 900)),
        ];
        final shortPlan = shortService.buildInitialLoadPlan(
          currentShorts: const <PostsModel>[],
          snapshotPosts: shortCandidates,
          isEligiblePost: (post) => post.video.isNotEmpty,
        );

        expect(
          shortPlan.replacementItems?.map((post) => post.docID).toList(),
          <String>['short-owned-1', 'short-owned-2', 'short-owned-3'],
        );
      },
    );
  });
}

PostsModel _videoPost(String id, DateTime timestamp) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 0.8,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: id,
    flood: false,
    floodCount: 0,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: '',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: 'thumb.webp',
    timeStamp: timestamp.millisecondsSinceEpoch,
    userID: 'u1',
    video: 'video.mp4',
    yorum: true,
  );
}
