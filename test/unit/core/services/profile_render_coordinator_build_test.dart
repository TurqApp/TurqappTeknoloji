import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/profile_render_coordinator.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('ProfileRenderCoordinator.buildMergedEntries', () {
    test('uses manifest reshare timestamp as fallback ordering signal', () {
      final coordinator = ProfileRenderCoordinator();
      final merged = coordinator.buildMergedEntries(
        allPosts: <PostsModel>[
          _post(id: 'own-post', userId: 'owner', timeStamp: 100),
        ],
        reshares: <PostsModel>[
          _post(
            id: 'reshare-post',
            userId: 'another-user',
            timeStamp: 10,
            reshareTimestamp: 500,
          ),
        ],
        reshareSortTimestampFor: (_, fallback) => fallback,
      );

      expect(merged, hasLength(2));
      expect((merged.first['post'] as PostsModel).docID, 'reshare-post');
      expect(merged.first['isReshare'], isTrue);
      expect(merged.first['timestamp'], 500);
    });
  });
}

PostsModel _post({
  required String id,
  required String userId,
  required int timeStamp,
  int? reshareTimestamp,
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
    metin: 'caption',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: 'https://cdn.turqapp.com/$id.jpg',
    timeStamp: timeStamp,
    userID: userId,
    authorNickname: 'nick_$userId',
    authorDisplayName: 'User $userId',
    authorAvatarUrl: 'https://cdn.turqapp.com/$userId.webp',
    video: '',
    yorum: true,
    reshareMap: <String, dynamic>{
      if (reshareTimestamp != null)
        'manifestReshareTimeStamp': reshareTimestamp,
    },
  );
}
