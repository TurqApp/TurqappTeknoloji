import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/profile_manifest_repository.dart';

Map<String, dynamic> _postItem(
  String docId, {
  String userId = 'user-a',
  String video = '',
}) {
  return <String, dynamic>{
    'docID': docId,
    'data': <String, dynamic>{
      'userID': userId,
      'authorNickname': 'nick_$userId',
      'authorDisplayName': 'User $userId',
      'authorAvatarUrl': 'https://cdn.turqapp.com/$userId.webp',
      'rozet': 'Mavi',
      'metin': 'caption',
      'thumbnail': 'https://cdn.turqapp.com/$docId.jpg',
      'img': <String>[
        'https://cdn.turqapp.com/${docId}_alt.jpg',
      ],
      'video': video,
      'hlsMasterUrl': video.isEmpty
          ? ''
          : 'https://cdn.turqapp.com/Posts/$docId/hls/master.m3u8',
      'hlsStatus': video.isEmpty ? 'none' : 'ready',
      'aspectRatio': 0.5625,
      'timeStamp': 1776710000000,
      'shortId': docId,
      'shortUrl': 'https://turqapp.com/p/$docId',
      'deletedPost': false,
      'gizlendi': false,
      'arsiv': false,
      'isUploading': false,
      'flood': false,
      'floodCount': 1,
      'paylasGizliligi': 0,
      'yorum': true,
      'stats': const <String, dynamic>{
        'likeCount': 10,
        'commentCount': 2,
        'savedCount': 1,
        'retryCount': 0,
        'statsCount': 100,
      },
    },
  };
}

void main() {
  group('ProfileManifestRepository', () {
    test('parses self-contained profile buckets from manifest json', () {
      final buckets = ProfileManifestRepository.parseManifestJson(
        jsonEncode(<String, dynamic>{
          'schemaVersion': 1,
          'manifestId': 'profile_user-a_v1',
          'header': const <String, dynamic>{
            'nickname': 'nick',
            'displayName': 'Display Name',
          },
          'all': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              _postItem('doc-1'),
              _postItem('doc-2',
                  video: 'https://cdn.turqapp.com/Posts/doc-2/video.mp4'),
            ],
          },
          'photos': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              _postItem('doc-1'),
            ],
          },
          'videos': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              _postItem('doc-2',
                  video: 'https://cdn.turqapp.com/Posts/doc-2/video.mp4'),
            ],
          },
          'reshares': const <String, dynamic>{
            'items': <Map<String, dynamic>>[]
          },
          'scheduled': const <String, dynamic>{
            'items': <Map<String, dynamic>>[]
          },
        }),
      );

      expect(buckets, isNotNull);
      expect(buckets!.all, hasLength(2));
      expect(buckets.photos.single.docID, 'doc-1');
      expect(buckets.videos.single.docID, 'doc-2');
      expect(buckets.all.first.authorAvatarUrl, contains('user-a'));
    });

    test('maps manifest header into profile header card shape', () {
      final header = ProfileManifestRepository.headerAsUserCard(
        const <String, dynamic>{
          'nickname': 'nick',
          'displayName': 'Display Name',
          'avatarUrl': 'https://cdn.turqapp.com/user-a.webp',
          'rozet': 'Mavi',
          'bio': 'bio',
          'adres': 'istanbul',
          'meslekKategori': 'engineer',
          'followerCount': 12,
          'followingCount': 7,
        },
      );

      expect(header['nickname'], 'nick');
      expect(header['displayName'], 'Display Name');
      expect(header['avatarUrl'], contains('user-a'));
      expect(header['counterOfFollowers'], 12);
      expect(header['counterOfFollowings'], 7);
    });

    test('returns null for malformed manifest json', () {
      expect(
        ProfileManifestRepository.parseManifestJson(
          jsonEncode(<String, dynamic>{'all': 'invalid'}),
        ),
        isNotNull,
      );
      final buckets = ProfileManifestRepository.parseManifestJson(
        jsonEncode(<String, dynamic>{'all': 'invalid'}),
      );
      expect(buckets!.all, isEmpty);
      expect(buckets.photos, isEmpty);
      expect(buckets.videos, isEmpty);
    });
  });
}
