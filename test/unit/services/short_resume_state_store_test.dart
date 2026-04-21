import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/short_resume_state_store.dart';
import 'package:turqappv2/Models/posts_model.dart';

PostsModel _buildPost(String docId) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 0.5625,
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
    metin: 'caption-$docId',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: 'thumb-$docId',
    timeStamp: 1700000000000,
    userID: 'user-1',
    authorNickname: 'nick',
    authorDisplayName: 'display',
    authorAvatarUrl: 'avatar',
    rozet: 'verified',
    video: 'video-$docId',
    hlsMasterUrl: 'hls-$docId',
    hlsStatus: 'ready',
    yorum: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ShortResumeStateStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('short-resume-test-');
    store = ShortResumeStateStore(
      directoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('short resume state store saves and loads remaining queue with cursor',
      () async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await store.save(
      userId: 'user-a',
      state: ShortResumeState(
        manifestId: 'manifest-1',
        cursorSlotIndex: 2,
        cursorItemIndex: 45,
        hasMore: true,
        savedAtMs: nowMs,
        remainingPosts: <PostsModel>[
          _buildPost('doc-2'),
          _buildPost('doc-3'),
        ],
      ),
    );

    final loaded = await store.load(userId: 'user-a');

    expect(loaded, isNotNull);
    expect(loaded!.manifestId, 'manifest-1');
    expect(loaded.cursorSlotIndex, 2);
    expect(loaded.cursorItemIndex, 45);
    expect(loaded.hasMore, isTrue);
    expect(loaded.remainingPosts.map((post) => post.docID).toList(), <String>[
      'doc-2',
      'doc-3',
    ]);
  });

  test('short resume state store clears expired state', () async {
    await store.save(
      userId: 'user-a',
      state: ShortResumeState(
        manifestId: 'manifest-1',
        cursorSlotIndex: 0,
        cursorItemIndex: 30,
        hasMore: true,
        savedAtMs: DateTime.now()
            .subtract(const Duration(hours: 30))
            .millisecondsSinceEpoch,
        remainingPosts: <PostsModel>[
          _buildPost('doc-1'),
        ],
      ),
    );

    final loaded = await store.load(userId: 'user-a');

    expect(loaded, isNull);
  });

  test('short resume state store keeps a large remaining queue intact',
      () async {
    final posts = List<PostsModel>.generate(
      5000,
      (index) => _buildPost('doc-$index'),
      growable: false,
    );

    await store.save(
      userId: 'user-a',
      state: ShortResumeState(
        manifestId: 'manifest-large',
        cursorSlotIndex: 17,
        cursorItemIndex: 83,
        hasMore: true,
        savedAtMs: DateTime.now().millisecondsSinceEpoch,
        remainingPosts: posts,
      ),
    );

    final loaded = await store.load(userId: 'user-a');

    expect(loaded, isNotNull);
    expect(loaded!.remainingPosts.length, 5000);
    expect(loaded.remainingPosts.first.docID, 'doc-0');
    expect(loaded.remainingPosts.last.docID, 'doc-4999');
    expect(loaded.cursorSlotIndex, 17);
    expect(loaded.cursorItemIndex, 83);
  });
}
