import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Models/posts_model.dart';

class FeedIndexEntry {
  final String docID;
  final Map<String, dynamic> postData;
  final String userID;
  final String nickname;
  final String avatarUrl;
  final String caption;
  final bool isPrivate;
  final int updatedAt;

  FeedIndexEntry({
    required this.docID,
    required this.postData,
    required this.userID,
    required this.nickname,
    required this.avatarUrl,
    required this.caption,
    required this.isPrivate,
    required this.updatedAt,
  });

  PostsModel toPostModel() => PostsModel.fromMap(postData, docID);

  Map<String, dynamic> toJson() => {
        'docID': docID,
        'postData': postData,
        'userID': userID,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'caption': caption,
        'isPrivate': isPrivate,
        'updatedAt': updatedAt,
      };

  factory FeedIndexEntry.fromJson(Map<String, dynamic> json) {
    return FeedIndexEntry(
      docID: (json['docID'] ?? '').toString(),
      postData: (json['postData'] as Map?)?.cast<String, dynamic>() ?? {},
      userID: (json['userID'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      isPrivate: json['isPrivate'] == true,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeedIndexStore {
  static const int _schemaVersion = 2;
  static const int _maxEntries = 250;
  static const Duration _cacheTtl = Duration(hours: 24);
  late final String _indexFilePath;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final dir = await getApplicationSupportDirectory();
    final indexDir = Directory('${dir.path}/feed_index');
    if (!await indexDir.exists()) {
      await indexDir.create(recursive: true);
    }
    _indexFilePath = '${indexDir.path}/feed_index.json';
    _ready = true;
  }

  Future<List<FeedIndexEntry>> loadEntries({
    int limit = 30,
    bool allowStale = true,
  }) async {
    if (!_ready) await init();
    final file = File(_indexFilePath);
    if (!await file.exists()) return const [];

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return const [];
      final raw = jsonDecode(content);
      List<dynamic> entriesRaw = const [];
      int updatedAtMs = 0;
      if (raw is List) {
        // Legacy format (v1): plain list.
        entriesRaw = raw;
      } else if (raw is Map<String, dynamic>) {
        final version = (raw['schemaVersion'] as num?)?.toInt() ?? 0;
        if (version != _schemaVersion) {
          await _deleteIndexFile();
          return const [];
        }
        entriesRaw = (raw['entries'] as List?) ?? const [];
        updatedAtMs = (raw['updatedAt'] as num?)?.toInt() ?? 0;
      } else {
        await _deleteIndexFile();
        return const [];
      }

      if (updatedAtMs > 0 && !allowStale) {
        final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAtMs;
        if (ageMs > _cacheTtl.inMilliseconds) {
          return const [];
        }
      }

      final entries = entriesRaw
          .whereType<Map>()
          .map((m) => FeedIndexEntry.fromJson(m.cast<String, dynamic>()))
          .where((e) => e.docID.isNotEmpty && e.postData.isNotEmpty)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries.take(limit).toList();
    } catch (_) {
      await _deleteIndexFile();
      return const [];
    }
  }

  Future<void> saveFromPosts(
    List<PostsModel> posts, {
    Map<String, Map<String, dynamic>> userMeta = const {},
  }) async {
    if (posts.isEmpty) return;
    if (!_ready) await init();

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await loadEntries(limit: _maxEntries, allowStale: true);
    final map = <String, FeedIndexEntry>{
      for (final e in existing) e.docID: e,
    };

    for (final post in posts) {
      final user = userMeta[post.userID] ?? const <String, dynamic>{};
      map[post.docID] = FeedIndexEntry(
        docID: post.docID,
        postData: post.toMap(),
        userID: post.userID,
        nickname: (user['nickname'] ?? '').toString(),
        avatarUrl: (user['pfImage'] ?? '').toString(),
        caption: post.metin,
        isPrivate: user['gizliHesap'] == true,
        updatedAt: now,
      );
    }

    final values = map.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trimmed = values.take(_maxEntries).toList();

    final file = File(_indexFilePath);
    final tmp = File('$_indexFilePath.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'entries': trimmed.map((e) => e.toJson()).toList(),
      }),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<void> _deleteIndexFile() async {
    if (!_ready) await init();
    try {
      final file = File(_indexFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
