import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/models.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  test('video cache entry exposes cached post model from persisted card data',
      () {
    final post = _buildShortPost(
      docId: 'short-doc-1',
      userId: 'author-1',
      rozet: 'mavi',
    );
    final entry = VideoCacheEntry(
      docID: post.docID,
      masterPlaylistUrl: post.playbackUrl,
      cardData: post.toMap(),
      totalSegmentCount: 4,
      segments: <String, CachedSegment>{
        '720p/segment_0.ts': CachedSegment(
          segmentUri: '720p/segment_0.ts',
          diskPath: '/tmp/segment_0.ts',
          sizeBytes: 10,
          cachedAt: DateTime.utc(2026, 3, 30),
        ),
        '720p/segment_1.ts': CachedSegment(
          segmentUri: '720p/segment_1.ts',
          diskPath: '/tmp/segment_1.ts',
          sizeBytes: 10,
          cachedAt: DateTime.utc(2026, 3, 30),
        ),
        '720p/segment_2.ts': CachedSegment(
          segmentUri: '720p/segment_2.ts',
          diskPath: '/tmp/segment_2.ts',
          sizeBytes: 10,
          cachedAt: DateTime.utc(2026, 3, 30),
        ),
        '720p/segment_3.ts': CachedSegment(
          segmentUri: '720p/segment_3.ts',
          diskPath: '/tmp/segment_3.ts',
          sizeBytes: 10,
          cachedAt: DateTime.utc(2026, 3, 30),
        ),
      },
    );

    final restored = entry.cachedPostModel;

    expect(restored, isNotNull);
    expect(restored!.docID, post.docID);
    expect(restored.userID, post.userID);
    expect(restored.rozet, 'mavi');
    expect(restored.playbackUrl, post.playbackUrl);
  });

  test('video cache entry json round-trip preserves card data', () {
    final post = _buildShortPost(
      docId: 'short-doc-2',
      userId: 'author-2',
      rozet: 'turkuaz',
    );
    final original = VideoCacheEntry(
      docID: post.docID,
      masterPlaylistUrl: post.playbackUrl,
      cardData: post.toMap(),
      totalSegmentCount: 1,
      lastUserInteractionAt: DateTime.utc(2026, 3, 30, 12),
      segments: <String, CachedSegment>{
        '720p/segment_0.ts': CachedSegment(
          segmentUri: '720p/segment_0.ts',
          diskPath: '/tmp/segment_0.ts',
          sizeBytes: 12,
          cachedAt: DateTime.utc(2026, 3, 30),
        ),
      },
    );

    final roundTripped = VideoCacheEntry.fromJson(original.toJson());

    expect(roundTripped.cachedPostModel, isNotNull);
    expect(roundTripped.cachedPostModel!.docID, post.docID);
    expect(roundTripped.cachedPostModel!.rozet, 'turkuaz');
    expect(roundTripped.cachedPostModel!.authorNickname, 'rozetli');
    expect(roundTripped.isFullyCached, isTrue);
    expect(
      roundTripped.lastUserInteractionAt?.millisecondsSinceEpoch,
      DateTime.utc(2026, 3, 30, 12).millisecondsSinceEpoch,
    );
  });
}

PostsModel _buildShortPost({
  required String docId,
  required String userId,
  required String rozet,
}) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 9 / 16,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: docId,
    flood: false,
    floodCount: 1,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: 'kisa video',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: 'Posts/$docId/thumb.jpg',
    timeStamp: DateTime.utc(2026, 3, 30).millisecondsSinceEpoch,
    userID: userId,
    authorNickname: 'rozetli',
    authorDisplayName: 'Rozetli Kullanici',
    authorAvatarUrl: 'https://cdn.turqapp.com/avatar.jpg',
    rozet: rozet,
    video: '',
    hlsMasterUrl: 'https://cdn.turqapp.com/Posts/$docId/hls/master.m3u8',
    hlsStatus: 'ready',
    hlsUpdatedAt: DateTime.utc(2026, 3, 30).millisecondsSinceEpoch,
    yorum: true,
  );
}
