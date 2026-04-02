import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_render_coordinator.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('FeedRenderCoordinator.buildMergedEntries', () {
    test('keeps the real feed post when a reshare event references it', () {
      final coordinator = FeedRenderCoordinator();
      final agendaList = <PostsModel>[
        _post(id: 'p1', timeStamp: 100),
      ];

      final merged = coordinator.buildMergedEntries(
        agendaList: agendaList,
        feedReshareEntries: <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'reshare',
            'post': _post(id: 'p1', timeStamp: 100),
            'reshareTimestamp': 500,
            'reshareUserID': 'reshare-user',
          },
        ],
        myReshares: const <String, int>{},
        currentUserId: 'viewer-1',
      );

      expect(merged, hasLength(1));
      expect(merged.first['model'], same(agendaList.first));
      expect(merged.first['reshare'], isFalse);
      expect(merged.first['timestamp'], 100);
      expect(merged.first['agendaIndex'], 0);
    });

    test('ignores reshare-only rows without a backing agenda post', () {
      final coordinator = FeedRenderCoordinator();

      final merged = coordinator.buildMergedEntries(
        agendaList: const <PostsModel>[],
        feedReshareEntries: <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'reshare',
            'post': _post(id: 'p1', timeStamp: 100),
            'reshareTimestamp': 500,
            'reshareUserID': 'reshare-user',
          },
        ],
        myReshares: const <String, int>{},
        currentUserId: 'viewer-1',
      );

      expect(merged, isEmpty);
    });

    test('preserves agenda order instead of re-sorting by timestamp', () {
      final coordinator = FeedRenderCoordinator();
      final agendaList = <PostsModel>[
        _post(id: 'first', timeStamp: 100),
        _post(id: 'second', timeStamp: 900),
      ];

      final merged = coordinator.buildMergedEntries(
        agendaList: agendaList,
        feedReshareEntries: const <Map<String, dynamic>>[],
        myReshares: const <String, int>{},
        currentUserId: 'viewer-1',
      );

      expect(merged, hasLength(2));
      expect((merged[0]['model'] as PostsModel).docID, 'first');
      expect((merged[1]['model'] as PostsModel).docID, 'second');
    });

    test('marks self-reshared posts without reordering agenda sequence', () {
      final coordinator = FeedRenderCoordinator();
      final agendaList = <PostsModel>[
        _post(id: 'older', timeStamp: 100),
        _post(id: 'mine', timeStamp: 90),
      ];

      final merged = coordinator.buildMergedEntries(
        agendaList: agendaList,
        feedReshareEntries: const <Map<String, dynamic>>[],
        myReshares: const <String, int>{
          'mine': 600,
        },
        currentUserId: 'viewer-1',
      );

      expect(merged, hasLength(2));
      expect((merged[0]['model'] as PostsModel).docID, 'older');
      expect((merged[1]['model'] as PostsModel).docID, 'mine');
      expect(merged[1]['reshare'], isTrue);
      expect(merged[1]['reshareUserID'], 'viewer-1');
      expect(merged[1]['timestamp'], 600);
    });
  });
}

PostsModel _post({
  required String id,
  required int timeStamp,
}) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 1,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: id,
    flood: false,
    floodCount: 0,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    isUploading: false,
    izBirakYayinTarihi: 0,
    konum: '',
    locationCity: '',
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
    thumbnail: '',
    timeStamp: timeStamp,
    userID: 'user-1',
    authorNickname: 'user-1',
    authorDisplayName: 'User 1',
    authorAvatarUrl: '',
    shortId: '',
    shortUrl: '',
    rozet: '',
    video: '',
    videoLook: const <String, dynamic>{},
    hlsMasterUrl: '',
    hlsStatus: 'none',
    hlsUpdatedAt: 0,
    yorum: true,
    yorumMap: const <String, dynamic>{},
    reshareMap: const <String, dynamic>{},
    poll: const <String, dynamic>{},
  );
}
