import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/launch_motor_selection_service.dart';
import 'package:turqappv2/Core/Services/launch_motor_surface_contract.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('LaunchMotorSelectionService', () {
    final anchorMs = DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch;
    const minuteSets = <List<int>>[
      <int>[0, 5, 10, 15, 20],
      <int>[1, 6, 11, 16, 21],
      <int>[2, 7, 12, 17, 22],
      <int>[3, 8, 13, 18, 23],
      <int>[4, 9, 14, 19, 24],
      <int>[5, 10, 15, 20, 25],
    ];

    test('resolves motor index and owned minutes from anchor minute', () {
      expect(
        LaunchMotorSelectionService.resolveMotorIndex(
          anchorMs: anchorMs,
          bandMinutes: 5,
          minuteSets: minuteSets,
        ),
        5,
      );
      expect(
        LaunchMotorSelectionService.resolveOwnedMinutes(
          anchorMs: anchorMs,
          bandMinutes: 5,
          minuteSets: minuteSets,
        ),
        <int>[5, 10, 15, 20, 25],
      );
    });

    test('analyzePool returns strict owned-minute selection', () {
      final snapshot = LaunchMotorSelectionService.analyzePool(
        latestPool: <PostsModel>[
          _post('a', DateTime(2026, 4, 14, 18, 25)),
          _post('b', DateTime(2026, 4, 14, 18, 24)),
          _post('c', DateTime(2026, 4, 14, 18, 20)),
          _post('d', DateTime(2026, 4, 14, 17, 15)),
        ],
        anchorMs: anchorMs,
        window: const Duration(days: 7),
        bandMinutes: 5,
        subsliceMs: 200,
        minuteSets: minuteSets,
      );

      expect(snapshot.motorIndex, 5);
      expect(snapshot.ownedMinutes, <int>[5, 10, 15, 20, 25]);
      expect(snapshot.queueCount, 3);
      expect(
        snapshot.strictSelection.map((post) => post.docID).toList(),
        <String>['a', 'c', 'd'],
      );
    });

    test(
        'buildPoolFillResult signals top-up need while filling remainder behind strict head',
        () {
      final result = LaunchMotorSelectionService.buildPoolFillResult(
        latestPool: <PostsModel>[
          _post('a', DateTime(2026, 4, 14, 18, 25)),
          _post('b', DateTime(2026, 4, 14, 18, 24)),
        ],
        anchorMs: anchorMs,
        contract: feedLaunchMotorContract,
        targetCount: 3,
      );

      expect(result.strictCount, 1);
      expect(result.needsTopUp(3), isTrue);
      expect(
        result.selectedPool.map((post) => post.docID).toList(),
        <String>['a', 'b'],
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
