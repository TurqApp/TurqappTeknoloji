import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_feed_application_service.dart';

void main() {
  group('Feed launch motor contract', () {
    final anchorMs = DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch;

    test('resolves owned minutes from anchor minute band', () {
      final service = AgendaFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );

      expect(service.resolveLaunchMotorIndex(), 5);
      expect(
        service.resolveLaunchMotorOwnedMinutes(),
        <int>[5, 18, 25, 44, 51],
      );
    });

    test('buildLaunchMotorPool keeps owned-minute candidates latest-first', () {
      final service = AgendaFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final ownedMinutes = service.resolveLaunchMotorOwnedMinutes();

      final selected = service.buildLaunchMotorPool(
        primaryCandidates: <PostsModel>[
          _post('p-1825', DateTime(2026, 4, 14, 18, 25)),
          _post('p-1826', DateTime(2026, 4, 14, 18, 26)),
          _post('p-1818', DateTime(2026, 4, 14, 18, 18)),
          _post('p-1751', DateTime(2026, 4, 14, 17, 51)),
        ],
        fallbackCandidates: const <PostsModel>[],
        targetCount: 4,
      );

      expect(
        selected.map((post) => post.docID).toList(growable: false),
        <String>['p-1825', 'p-1818', 'p-1751'],
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

PostsModel _post(String id, DateTime time) {
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
    img: const <String>['image.webp'],
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
