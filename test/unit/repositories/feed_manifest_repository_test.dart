import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';

Map<String, dynamic> _item(
  String docId, {
  String userId = 'user-a',
  String canonicalId = '',
  bool floodRoot = false,
  String shortUrl = '',
}) {
  return <String, dynamic>{
    'docId': docId,
    if (canonicalId.isNotEmpty) 'canonicalId': canonicalId,
    'userID': userId,
    'authorNickname': 'nick_$userId',
    'authorDisplayName': 'User $userId',
    'authorAvatarUrl': 'https://cdn.turqapp.com/$userId.webp',
    'rozet': 'Mavi',
    'metin': 'caption',
    'thumbnail': 'https://cdn.turqapp.com/$docId.jpg',
    'posterCandidates': <String>[
      'https://cdn.turqapp.com/$docId.jpg',
      'https://cdn.turqapp.com/${docId}_alt.jpg',
    ],
    'video': '',
    'hlsMasterUrl': 'https://cdn.turqapp.com/Posts/$docId/hls/master.m3u8',
    'hlsStatus': 'ready',
    'hasPlayableVideo': true,
    'aspectRatio': 0.5625,
    'timeStamp': 1776710000000,
    'createdAtTs': 1776710000000,
    'shortId': docId,
    'shortUrl': shortUrl.isEmpty ? 'https://turqapp.com/p/$docId' : shortUrl,
    'stats': const <String, dynamic>{
      'likeCount': 10,
      'commentCount': 2,
      'savedCount': 1,
      'retryCount': 0,
      'statsCount': 100,
    },
    'flags': <String, dynamic>{
      'deletedPost': false,
      'gizlendi': false,
      'arsiv': false,
      'flood': false,
      'floodCount': floodRoot ? 4 : 1,
      'mainFlood': '',
      'isFloodRoot': floodRoot,
      'paylasGizliligi': 0,
    },
  };
}

void main() {
  group('FeedManifestRepository', () {
    test('parses feed manifest slot entries into self-contained posts', () {
      final entries = FeedManifestRepository.parseSlotEntries(
        jsonEncode(<String, dynamic>{
          'slotId': 'slot_12',
          'items': <Map<String, dynamic>>[
            _item('doc-1', userId: 'user-a'),
            _item('flood-root', userId: 'user-b', floodRoot: true),
          ],
        }),
        fallbackSlotId: 'slot_00',
        slotPath: 'feedManifest/2026-04-21/slots/slot_12.json',
      );

      expect(entries, hasLength(2));
      expect(entries.first.slotId, 'slot_12');
      expect(
          entries.first.slotPath, 'feedManifest/2026-04-21/slots/slot_12.json');
      expect(entries.first.canonicalId, 'doc-1');
      expect(entries.first.post.shortUrl, 'https://turqapp.com/p/doc-1');
      expect(entries.first.post.authorAvatarUrl, contains('user-a'));
      expect(entries[1].canonicalId, 'flood-root');
      expect(entries[1].post.isFloodSeriesRoot, isTrue);
    });

    test('dedupes canonical ids inside a slot', () {
      final entries = FeedManifestRepository.parseSlotEntries(
        jsonEncode(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            _item('root', canonicalId: 'thread'),
            _item('root_1', canonicalId: 'thread'),
            _item('other', canonicalId: 'other'),
          ],
        }),
        fallbackSlotId: 'slot_03',
        slotPath: 'feedManifest/2026-04-21/slots/slot_03.json',
      );

      expect(
        entries.map((entry) => entry.post.docID).toList(growable: false),
        <String>['root', 'other'],
      );
    });

    test('uses fallback slot id when payload omits slot id', () {
      final entries = FeedManifestRepository.parseSlotEntries(
        jsonEncode(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            _item('doc-1'),
          ],
        }),
        fallbackSlotId: 'slot_06',
        slotPath: 'feedManifest/2026-04-21/slots/slot_06.json',
      );

      expect(entries.single.slotId, 'slot_06');
    });
  });
}
