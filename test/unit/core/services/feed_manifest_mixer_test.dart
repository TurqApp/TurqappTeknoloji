import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_manifest_repository.dart';
import 'package:turqappv2/Core/Services/feed_manifest_mixer.dart';

FeedManifestEntry _entry(
  String docId, {
  String userId = 'user-a',
  String canonicalId = '',
  bool floodRoot = false,
}) {
  return FeedManifestRepository.parseSlotEntries(
    jsonEncode(<String, dynamic>{
      'slotId': 'slot_12',
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
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
          ],
          'video': '',
          'hlsMasterUrl': 'https://cdn.turqapp.com/$docId/master.m3u8',
          'hlsStatus': 'ready',
          'hasPlayableVideo': true,
          'aspectRatio': 0.5625,
          'timeStamp': 1776710000000,
          'createdAtTs': 1776710000000,
          'shortId': docId,
          'shortUrl': 'https://turqapp.com/p/$docId',
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
        },
      ],
    }),
    fallbackSlotId: 'slot_12',
    slotPath: 'feedManifest/2026-04-21/slots/slot_12.json',
  ).single;
}

List<String> _docIds(FeedManifestDeckResult result) =>
    result.entries.map((entry) => entry.post.docID).toList(growable: false);

void main() {
  group('FeedManifestMixer', () {
    const mixer = FeedManifestMixer();

    test('builds deterministic but seed-specific deck order', () {
      final entries = List<FeedManifestEntry>.generate(
        40,
        (index) => _entry('doc-$index', userId: 'user-${index % 8}'),
      );

      final first = mixer.buildDeck(
        manifestEntries: entries,
        seed: 100,
        limit: 20,
      );
      final sameSeed = mixer.buildDeck(
        manifestEntries: entries,
        seed: 100,
        limit: 20,
      );
      final otherSeed = mixer.buildDeck(
        manifestEntries: entries,
        seed: 101,
        limit: 20,
      );

      expect(_docIds(first), _docIds(sameSeed));
      expect(_docIds(first), isNot(_docIds(otherSeed)));
    });

    test(
        'keeps recent startup head penalties out of the new head when possible',
        () {
      final entries = List<FeedManifestEntry>.generate(
        40,
        (index) => _entry('doc-$index', userId: 'user-${index % 10}'),
      );
      final result = mixer.buildDeck(
        manifestEntries: entries,
        seed: 7,
        limit: 20,
        headPenaltyCanonicalIds: <String>{'doc-1', 'doc-2', 'doc-3'},
        headPenaltyDepth: 20,
      );

      expect(_docIds(result), isNot(contains('doc-1')));
      expect(_docIds(result), isNot(contains('doc-2')));
      expect(_docIds(result), isNot(contains('doc-3')));
    });

    test('dedupes canonical flood ids across manifest and gap sources', () {
      final result = mixer.buildDeck(
        manifestEntries: <FeedManifestEntry>[
          _entry('flood-root', userId: 'user-a', floodRoot: true),
          _entry('regular', userId: 'user-b'),
        ],
        gapEntries: <FeedManifestEntry>[
          _entry('flood-root_1', userId: 'user-a', canonicalId: 'flood-root'),
          _entry('gap-1', userId: 'user-c'),
        ],
        seed: 11,
        limit: 10,
      );

      expect(_docIds(result).where((docId) => docId.startsWith('flood-root')),
          hasLength(1));
      expect(result.skippedDuplicateCount, 1);
    });

    test('spaces authors without dropping same-author fallback posts', () {
      final mixedUsers = mixer.buildDeck(
        manifestEntries: <FeedManifestEntry>[
          _entry('a-1', userId: 'a'),
          _entry('a-2', userId: 'a'),
          _entry('b-1', userId: 'b'),
          _entry('c-1', userId: 'c'),
          _entry('d-1', userId: 'd'),
        ],
        seed: 4,
        limit: 5,
        minUserSpacing: 2,
      );
      final userIds = mixedUsers.entries
          .map((entry) => entry.post.userID)
          .toList(growable: false);

      for (var i = 1; i < userIds.length; i++) {
        expect(userIds[i], isNot(userIds[i - 1]));
      }

      final sameUserOnly = mixer.buildDeck(
        manifestEntries: List<FeedManifestEntry>.generate(
          5,
          (index) => _entry('same-$index', userId: 'same-user'),
        ),
        seed: 4,
        limit: 5,
        minUserSpacing: 2,
      );

      expect(sameUserOnly.entries, hasLength(5));
    });

    test('interleaves Typesense gap candidates without letting them dominate',
        () {
      final result = mixer.buildDeck(
        manifestEntries: List<FeedManifestEntry>.generate(
          40,
          (index) => _entry('manifest-$index', userId: 'm-${index % 8}'),
        ),
        gapEntries: List<FeedManifestEntry>.generate(
          20,
          (index) => _entry('gap-$index', userId: 'g-${index % 4}'),
        ),
        seed: 12,
        limit: 24,
        gapEvery: 6,
      );

      expect(result.entries, hasLength(24));
      expect(result.gapCount, lessThanOrEqualTo(4));
      expect(result.manifestCount, greaterThan(result.gapCount));
      expect(
          result.entries.take(5).every(
                (entry) => entry.source == FeedManifestDeckSource.manifest,
              ),
          isTrue);
    });

    test('filters consumed canonical ids and doc ids', () {
      final result = mixer.buildDeck(
        manifestEntries: <FeedManifestEntry>[
          _entry('doc-1'),
          _entry('doc-2'),
          _entry('doc-3'),
        ],
        seed: 2,
        limit: 10,
        consumedCanonicalIds: <String>{'doc-1'},
        consumedDocIds: <String>{'doc-3'},
      );

      expect(_docIds(result), <String>['doc-2']);
      expect(result.skippedConsumedCount, 2);
    });

    test('soft-caps dominant authors without underfilling the deck', () {
      final result = mixer.buildDeck(
        manifestEntries: <FeedManifestEntry>[
          ...List<FeedManifestEntry>.generate(
            8,
            (index) => _entry('heavy-$index', userId: 'heavy'),
          ),
          ...List<FeedManifestEntry>.generate(
            6,
            (index) => _entry('light-a-$index', userId: 'light-a'),
          ),
          ...List<FeedManifestEntry>.generate(
            6,
            (index) => _entry('light-b-$index', userId: 'light-b'),
          ),
          ...List<FeedManifestEntry>.generate(
            6,
            (index) => _entry('light-c-$index', userId: 'light-c'),
          ),
        ],
        seed: 23,
        limit: 12,
        minUserSpacing: 2,
        maxItemsPerUser: 3,
      );

      final counts = <String, int>{};
      for (final entry in result.entries) {
        counts.update(entry.post.userID, (value) => value + 1,
            ifAbsent: () => 1);
      }

      expect(result.entries, hasLength(12));
      expect(counts['heavy'], lessThanOrEqualTo(3));
    });
  });
}
