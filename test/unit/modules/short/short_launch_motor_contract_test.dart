import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Short/short_feed_application_service.dart';

void main() {
  group('Short launch motor contract', () {
    final anchorMs = DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch;

    test('resolves owned minutes from anchor minute band', () {
      final service = ShortFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );

      expect(service.resolveLaunchMotorIndex(), 5);
      expect(
        service.resolveLaunchMotorOwnedMinutes(),
        <int>[9, 22, 29, 36, 55],
      );
    });

    test('buildLaunchMotorPool keeps owned-minute candidates latest-first', () {
      final service = ShortFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final ownedMinutes = service.resolveLaunchMotorOwnedMinutes();

      final selected = service.buildLaunchMotorPool(
        <PostsModel>[
          _short('s-1822', DateTime(2026, 4, 14, 18, 22)),
          _short('s-1825', DateTime(2026, 4, 14, 18, 25)),
          _short('s-1729', DateTime(2026, 4, 14, 17, 29)),
          _short('s-1655', DateTime(2026, 4, 14, 16, 55)),
        ],
        targetCount: 4,
      );

      expect(
        selected.map((post) => post.docID).toList(growable: false),
        <String>['s-1822', 's-1729', 's-1655'],
      );
      expect(
        selected
            .map(
              (post) => DateTime.fromMillisecondsSinceEpoch(
                post.timeStamp.toInt(),
              ).minute,
            )
            .every(ownedMinutes.contains),
        isTrue,
      );
    });
  });
}

PostsModel _short(String id, DateTime time) {
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
    timeStamp: time.millisecondsSinceEpoch,
    userID: 'u1',
    video: 'video.mp4',
    yorum: true,
  );
}
