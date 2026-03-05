import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Models/posts_model.dart';

enum IndexPoolKind {
  feed,
  shortFullscreen,
  explore,
  story,
}

class IndexPoolEntry {
  final String docID;
  final String kind;
  final Map<String, dynamic> postData;
  final String userID;
  final String nickname;
  final String avatarUrl;
  final String caption;
  final int updatedAt;

  IndexPoolEntry({
    required this.docID,
    required this.kind,
    required this.postData,
    required this.userID,
    required this.nickname,
    required this.avatarUrl,
    required this.caption,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'docID': docID,
        'kind': kind,
        'postData': postData,
        'userID': userID,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'caption': caption,
        'updatedAt': updatedAt,
      };

  factory IndexPoolEntry.fromJson(Map<String, dynamic> json) {
    return IndexPoolEntry(
      docID: (json['docID'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
      postData: (json['postData'] as Map?)?.cast<String, dynamic>() ?? {},
      userID: (json['userID'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class IndexPoolStore {
  static const int _schemaVersion = 2;
  static const int _maxEntriesPerKind = 250;
  static const Duration _cacheTtl = Duration(hours: 24);
  late final String _filePath;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final dir = await getApplicationSupportDirectory();
    final poolDir = Directory('${dir.path}/index_pool');
    if (!await poolDir.exists()) {
      await poolDir.create(recursive: true);
    }
    _filePath = '${poolDir.path}/pool.json';
    _ready = true;
  }

  Future<List<IndexPoolEntry>> _loadAll({bool allowStale = true}) async {
    if (!_ready) await init();
    final file = File(_filePath);
    if (!await file.exists()) return const [];
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return const [];
      final raw = jsonDecode(content);
      List<dynamic> entriesRaw = const [];
      int updatedAtMs = 0;

      if (raw is List) {
        // Legacy format (v1): plain entries list.
        entriesRaw = raw;
      } else if (raw is Map<String, dynamic>) {
        final version = (raw['schemaVersion'] as num?)?.toInt() ?? 0;
        if (version != _schemaVersion) {
          await _deletePoolFile();
          return const [];
        }
        entriesRaw = (raw['entries'] as List?) ?? const [];
        updatedAtMs = (raw['updatedAt'] as num?)?.toInt() ?? 0;
      } else {
        await _deletePoolFile();
        return const [];
      }

      if (updatedAtMs > 0 && !allowStale) {
        final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAtMs;
        if (ageMs > _cacheTtl.inMilliseconds) {
          return const [];
        }
      }

      return entriesRaw
          .whereType<Map>()
          .map((m) => IndexPoolEntry.fromJson(m.cast<String, dynamic>()))
          .where((e) => e.docID.isNotEmpty && e.kind.isNotEmpty)
          .toList();
    } catch (_) {
      await _deletePoolFile();
      return const [];
    }
  }

  Future<void> _persistAll(List<IndexPoolEntry> all) async {
    if (!_ready) await init();
    final file = File(_filePath);
    final tmp = File('$_filePath.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'entries': all.map((e) => e.toJson()).toList(),
      }),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  Future<void> _deletePoolFile() async {
    if (!_ready) await init();
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<List<PostsModel>> loadPosts(
    IndexPoolKind kind, {
    int limit = 20,
    bool allowStale = true,
  }) async {
    final k = kind.name;
    final all = await _loadAll(allowStale: allowStale);
    final filtered = all.where((e) => e.kind == k).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered
        .take(limit)
        .map((e) => PostsModel.fromMap(e.postData, e.docID))
        .toList();
  }

  Future<void> savePosts(
    IndexPoolKind kind,
    List<PostsModel> posts, {
    Map<String, Map<String, dynamic>> userMeta = const {},
  }) async {
    if (posts.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final k = kind.name;
    final all = await _loadAll(allowStale: true);

    final map = <String, IndexPoolEntry>{};
    for (final entry in all) {
      final key = '${entry.kind}:${entry.docID}';
      map[key] = entry;
    }

    for (final post in posts) {
      final user = userMeta[post.userID] ?? const <String, dynamic>{};
      final e = IndexPoolEntry(
        docID: post.docID,
        kind: k,
        postData: post.toMap(),
        userID: post.userID,
        nickname: (user['nickname'] ?? '').toString(),
        avatarUrl: (user['pfImage'] ?? '').toString(),
        caption: post.metin,
        updatedAt: now,
      );
      map['$k:${post.docID}'] = e;
    }

    final values = map.values.toList();
    final byKind = <String, List<IndexPoolEntry>>{};
    for (final entry in values) {
      byKind.putIfAbsent(entry.kind, () => []).add(entry);
    }

    final output = <IndexPoolEntry>[];
    byKind.forEach((kindKey, entries) {
      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      output.addAll(entries.take(_maxEntriesPerKind));
    });

    await _persistAll(output);
  }

  Future<void> removePosts(IndexPoolKind kind, List<String> docIDs) async {
    if (docIDs.isEmpty) return;
    final k = kind.name;
    final removeSet = docIDs.toSet();
    final all = await _loadAll(allowStale: true);
    final filtered = all
        .where((e) => !(e.kind == k && removeSet.contains(e.docID)))
        .toList();
    await _persistAll(filtered);
  }
}
