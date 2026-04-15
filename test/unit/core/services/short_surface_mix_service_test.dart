import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/short_surface_mix_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('excludeFeedVisibleShortConflicts', () {
    test('filters doc ids already visible on feed', () {
      final filtered = excludeFeedVisibleShortConflicts(
        <PostsModel>[
          _post('feed-1'),
          _post('short-1'),
          _post('short-2'),
        ],
        <String>{'feed-1'},
        fallbackToOriginalWhenEmpty: false,
      );

      expect(
          filtered.map((post) => post.docID).toList(growable: false), <String>[
        'short-1',
        'short-2',
      ]);
    });

    test('returns empty when every candidate conflicts and fallback is off',
        () {
      final filtered = excludeFeedVisibleShortConflicts(
        <PostsModel>[
          _post('feed-1'),
          _post('feed-2'),
        ],
        <String>{'feed-1', 'feed-2'},
        fallbackToOriginalWhenEmpty: false,
      );

      expect(filtered, isEmpty);
    });

    test(
        'keeps original list when every candidate conflicts and fallback is on',
        () {
      final filtered = excludeFeedVisibleShortConflicts(
        <PostsModel>[
          _post('feed-1'),
          _post('feed-2'),
        ],
        <String>{'feed-1', 'feed-2'},
      );

      expect(
          filtered.map((post) => post.docID).toList(growable: false), <String>[
        'feed-1',
        'feed-2',
      ]);
    });
  });
}

PostsModel _post(String docId) => PostsModel.fromMap(
      <String, dynamic>{
        'hlsMasterUrl': 'Posts/$docId/hls/master.m3u8',
        'hlsStatus': 'ready',
        'rozet': 'gri',
        'flood': false,
        'mainFlood': '',
        'floodCount': 0,
      },
      docId,
    );
