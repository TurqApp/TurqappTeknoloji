import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('PostsModel flood contract', () {
    test('floodCount greater than one marks root as flood series', () {
      final post = _post(
        id: 'flood_root',
        floodCount: 3,
      );

      expect(post.isFloodMember, isFalse);
      expect(post.isFloodSeriesRoot, isTrue);
      expect(post.isFloodSeriesContent, isTrue);
    });

    test('mainFlood marks child as flood member even without root count', () {
      final post = _post(
        id: 'flood_child',
        floodCount: 1,
        mainFlood: 'flood_root',
      );

      expect(post.isFloodMember, isTrue);
      expect(post.isFloodSeriesRoot, isFalse);
      expect(post.isFloodSeriesContent, isTrue);
    });
  });
}

PostsModel _post({
  required String id,
  required int floodCount,
  String mainFlood = '',
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
    floodCount: floodCount,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: mainFlood,
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
    timeStamp: 0,
    userID: 'u1',
    video: '',
    yorum: true,
  );
}
