import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Short/short_ad_render_plan.dart';

void main() {
  group('Short ad render plan', () {
    test('keeps organic flow untouched when ad is not renderable', () {
      final posts = List<PostsModel>.generate(
        6,
        (index) => _short('short-$index'),
      );

      final plan = buildShortAdRenderPlan(
        posts,
        adReady: false,
      );

      expect(plan.entries.length, 6);
      expect(plan.entries.every((entry) => !entry.isAd), isTrue);
      expect(plan.renderIndexForOrganicIndex(0), 0);
      expect(plan.renderIndexForOrganicIndex(5), 5);
      expect(plan.organicIndexForRenderIndex(5), 5);
    });

    test('can reserve fallback ad pages before Google ad is renderable', () {
      final posts = List<PostsModel>.generate(
        6,
        (index) => _short('short-$index'),
      );

      final plan = buildShortAdRenderPlan(
        posts,
        adReady: false,
        showFallbackWhenNotReady: true,
      );

      expect(plan.entries.length, 7);
      expect(plan.entries[5].isAd, isTrue);
      expect(plan.renderIndexForOrganicIndex(5), 6);
      expect(plan.organicIndexForRenderIndex(5), isNull);
      expect(plan.organicIndexForRenderIndex(6), 5);
    });

    test('inserts ad pages only after full frequency windows', () {
      final posts = List<PostsModel>.generate(
        11,
        (index) => _short('short-$index'),
      );

      final plan = buildShortAdRenderPlan(
        posts,
        adReady: true,
      );

      expect(plan.entries.length, 13);
      expect(plan.entries[5].isAd, isTrue);
      expect(plan.entries[11].isAd, isTrue);
      expect(plan.entries[12].organicIndex, 10);
    });

    test('maps organic and render indices around inserted ad pages', () {
      final posts = List<PostsModel>.generate(
        7,
        (index) => _short('short-$index'),
      );

      final plan = buildShortAdRenderPlan(
        posts,
        adReady: true,
      );

      expect(plan.renderIndexForOrganicIndex(4), 4);
      expect(plan.renderIndexForOrganicIndex(5), 6);
      expect(plan.organicIndexForRenderIndex(5), isNull);
      expect(plan.organicIndexForRenderIndex(6), 5);
    });
  });
}

PostsModel _short(String id) {
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
    timeStamp: DateTime(2026, 4, 20, 12, 0).millisecondsSinceEpoch,
    userID: 'u1',
    video: 'video.mp4',
    yorum: true,
  );
}
