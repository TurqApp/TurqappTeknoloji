import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('PostsModel poster contract', () {
    test('skips speculative self thumbnail when media points to source post',
        () {
      final post = PostsModel.fromMap(
        _videoPostMap(
          docId: 'curated_doc',
          thumbnail: 'https://cdn.turqapp.com/Posts/curated_doc/thumbnail.webp',
          hlsMasterUrl:
              'https://cdn.turqapp.com/Posts/source_doc/hls/master.m3u8',
          originalPostID: 'source_doc',
        ),
        'curated_doc',
      );

      expect(
        post.preferredVideoPosterUrls,
        isNot(contains(
            'https://cdn.turqapp.com/Posts/curated_doc/thumbnail.webp')),
      );
      expect(
        post.preferredVideoPosterUrls.first,
        'https://cdn.turqapp.com/Posts/source_doc/thumbnail.webp',
      );
    });

    test('keeps self thumbnail fallback when no source media exists', () {
      final post = PostsModel.fromMap(
        _videoPostMap(
          docId: 'regular_doc',
          thumbnail: '',
          hlsMasterUrl:
              'https://cdn.turqapp.com/Posts/regular_doc/hls/master.m3u8',
        ),
        'regular_doc',
      );

      expect(
        post.preferredVideoPosterUrls,
        contains('https://cdn.turqapp.com/Posts/regular_doc/thumbnail.webp'),
      );
    });
  });
}

Map<String, dynamic> _videoPostMap({
  required String docId,
  required String thumbnail,
  required String hlsMasterUrl,
  String originalPostID = '',
}) {
  return <String, dynamic>{
    'userID': 'user_1',
    'authorNickname': 'nick',
    'authorDisplayName': 'Display',
    'authorAvatarUrl': 'https://cdn.turqapp.com/users/user_1/avatar.webp',
    'rozet': 'Mavi',
    'metin': 'video',
    'thumbnail': thumbnail,
    'img': const <String>[],
    'video': hlsMasterUrl,
    'hlsMasterUrl': hlsMasterUrl,
    'hlsStatus': 'ready',
    'aspectRatio': 0.5625,
    'timeStamp': 1779540000123,
    'shortId': 'abcdef',
    'shortUrl': 'https://turqapp.com/p/abcdef',
    'stats': const <String, dynamic>{},
    'deletedPost': false,
    'gizlendi': false,
    'arsiv': false,
    'flood': false,
    'floodCount': 0,
    'paylasGizliligi': 0,
    'isUploading': false,
    'originalPostID': originalPostID,
    'docID': docId,
  };
}
