import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
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
  final Map<String, dynamic> cardData;
  final String userID;
  final String nickname;
  final String avatarUrl;
  final String caption;
  final int updatedAt;

  IndexPoolEntry({
    required this.docID,
    required this.kind,
    required Map<String, dynamic> cardData,
    required this.userID,
    required this.nickname,
    required this.avatarUrl,
    required this.caption,
    required this.updatedAt,
  }) : cardData = _cloneIndexPoolMap(cardData);

  Map<String, dynamic> toJson() => {
        'docID': docID,
        'kind': kind,
        'cardData': _cloneIndexPoolMap(cardData),
        'userID': userID,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'caption': caption,
        'updatedDate': updatedAt,
      };

  factory IndexPoolEntry.fromJson(Map<String, dynamic> json) {
    return IndexPoolEntry(
      docID: (json['docID'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
      cardData: _cloneIndexPoolMap(
        (json['cardData'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      userID: (json['userID'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      updatedAt: (json['updatedDate'] as num?)?.toInt() ?? 0,
    );
  }
}

Map<String, dynamic> _cloneIndexPoolMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _cloneIndexPoolValue(value)),
  );
}

dynamic _cloneIndexPoolValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneIndexPoolValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneIndexPoolValue).toList(growable: false);
  }
  return value;
}

class IndexPoolStore {
  static IndexPoolStore? maybeFind() {
    final isRegistered = Get.isRegistered<IndexPoolStore>();
    if (!isRegistered) return null;
    return Get.find<IndexPoolStore>();
  }

  static IndexPoolStore ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(IndexPoolStore(), permanent: permanent);
  }

  static const int _schemaVersion = 5;
  static const int _maxEntriesPerKind = 250;
  static const Duration _poolFileTtl = Duration(hours: 24);
  static const Duration _fallbackTtl = Duration(minutes: 5);
  static const Map<IndexPoolKind, Duration> _kindTtl = {
    IndexPoolKind.feed: Duration(minutes: 5),
    IndexPoolKind.explore: Duration(minutes: 5),
    IndexPoolKind.shortFullscreen: Duration(minutes: 3),
    IndexPoolKind.story: Duration(minutes: 2),
  };
  String? _filePath;
  bool _ready = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_ready) return;
    final pending = _initFuture;
    if (pending != null) {
      await pending;
      return;
    }

    _initFuture = _performInit();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _performInit() async {
    final dir = await getApplicationSupportDirectory();
    final poolDir = Directory('${dir.path}/index_pool');
    if (!await poolDir.exists()) {
      await poolDir.create(recursive: true);
    }
    _filePath ??= '${poolDir.path}/pool.json';
    _ready = true;
  }

  String get _resolvedFilePath {
    final path = _filePath;
    if (path == null || path.isEmpty) {
      throw StateError('Index pool path hazir degil');
    }
    return path;
  }

  Future<List<IndexPoolEntry>> _loadAll({bool allowStale = true}) async {
    if (!_ready) await init();
    final file = File(_resolvedFilePath);
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
        updatedAtMs = (raw['updatedDate'] as num?)?.toInt() ?? 0;
      } else {
        await _deletePoolFile();
        return const [];
      }

      if (updatedAtMs > 0 && !allowStale) {
        final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAtMs;
        if (ageMs > _poolFileTtl.inMilliseconds) {
          await _deletePoolFile();
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
    final filePath = _resolvedFilePath;
    final file = File(filePath);
    final tmp = File('$filePath.tmp');
    final payload = jsonEncode({
      'schemaVersion': _schemaVersion,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
      'entries': all.map((e) => e.toJson()).toList(),
    });
    await file.parent.create(recursive: true);
    await tmp.writeAsString(payload, flush: true);
    try {
      await tmp.rename(file.path);
    } on FileSystemException {
      // Some Android devices occasionally fail rename() if parent path is
      // transiently unavailable. Fallback keeps pool write durable even if
      // tmp file is no longer present.
      await file.parent.create(recursive: true);
      await file.writeAsString(payload, flush: true);
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }
  }

  Future<void> _deletePoolFile() async {
    if (!_ready) await init();
    try {
      final file = File(_resolvedFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Transitional helper while this service is being demoted to a warm-launch
  /// pool instead of the primary snapshot store.
  Future<void> clear() async {
    await _deletePoolFile();
  }

  Future<List<PostsModel>> loadPosts(
    IndexPoolKind kind, {
    int limit = 20,
    bool allowStale = true,
  }) async {
    final k = kind.name;
    final all = await _loadAll(allowStale: allowStale);
    final now = DateTime.now().millisecondsSinceEpoch;
    final ttlMs = (_kindTtl[kind] ?? _fallbackTtl).inMilliseconds;
    final filtered = all.where((e) => e.kind == k).where((entry) {
      if (allowStale) return true;
      if (entry.updatedAt <= 0) return false;
      return (now - entry.updatedAt) <= ttlMs;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final malformedIds = <String>{};
    final output = <PostsModel>[];
    for (final entry in filtered) {
      try {
        output.add(PostsModel.fromMap(entry.cardData, entry.docID));
      } catch (_) {
        malformedIds.add(entry.docID);
      }
      if (output.length >= limit) {
        break;
      }
    }
    if (malformedIds.isNotEmpty) {
      final repaired = all
          .where((entry) =>
              !(entry.kind == k && malformedIds.contains(entry.docID)))
          .toList(growable: false);
      await _persistAll(repaired);
    }
    return output;
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
        cardData: _buildCardData(post, userMeta[post.userID]),
        userID: post.userID,
        nickname: (user['nickname'] ?? '').toString(),
        avatarUrl: (user['avatarUrl'] ?? '').toString(),
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

  Future<void> clearKind(IndexPoolKind kind) async {
    final k = kind.name;
    final all = await _loadAll(allowStale: true);
    final filtered =
        all.where((entry) => entry.kind != k).toList(growable: false);
    if (filtered.length == all.length) {
      return;
    }
    await _persistAll(filtered);
  }

  Map<String, dynamic> _buildCardData(
    PostsModel post,
    Map<String, dynamic>? user,
  ) {
    final authorNickname = (post.authorNickname.isNotEmpty
            ? post.authorNickname
            : (user?['nickname'] ?? ''))
        .toString();
    final authorDisplayName = (post.authorDisplayName.isNotEmpty
            ? post.authorDisplayName
            : (user?['displayName'] ?? ''))
        .toString();
    final authorAvatarUrl = (post.authorAvatarUrl.isNotEmpty
            ? post.authorAvatarUrl
            : (user?['avatarUrl'] ?? ''))
        .toString();
    final rozet = (post.rozet.isNotEmpty ? post.rozet : (user?['rozet'] ?? ''))
        .toString();

    return <String, dynamic>{
      'metin': post.metin,
      'img': post.img,
      'thumbnail': post.thumbnail,
      'video': post.video,
      'hlsMasterUrl': post.hlsMasterUrl,
      'hlsStatus': post.hlsStatus,
      'hlsUpdatedAt': post.hlsUpdatedAt,
      'timeStamp': post.timeStamp,
      'editTime': post.editTime ?? 0,
      'authorNickname': authorNickname,
      'authorDisplayName': authorDisplayName,
      'authorAvatarUrl': authorAvatarUrl,
      'rozet': rozet,
      'userID': post.userID,
      'paylasGizliligi': post.paylasGizliligi,
      'arsiv': post.arsiv,
      'deletedPost': post.deletedPost,
      'gizlendi': post.gizlendi,
      'isUploading': post.isUploading,
      'aspectRatio': post.aspectRatio,
      'flood': post.flood,
      'floodCount': post.floodCount,
      'mainFlood': post.mainFlood,
      'locationCity': post.locationCity,
      'konum': post.konum,
      'originalPostID': post.originalPostID,
      'originalUserID': post.originalUserID,
      'quotedPost': post.quotedPost,
      'tags': post.tags,
      'yorum': post.yorum,
      'yorumMap': post.yorumMap,
      'reshareMap': post.reshareMap,
      'poll': post.poll,
      'ad': post.ad,
      'isAd': post.isAd,
      'debugMode': false,
      'deletedPostTime': post.deletedPostTime,
      'izBirakYayinTarihi': post.izBirakYayinTarihi,
      'scheduledAt': post.scheduledAt,
      'sikayetEdildi': post.sikayetEdildi,
      'stabilized': post.stabilized,
      'videoLook': post.videoLook,
      'stats': <String, dynamic>{
        'commentCount': post.stats.commentCount,
        'likeCount': post.stats.likeCount,
        'reportedCount': post.stats.reportedCount,
        'retryCount': post.stats.retryCount,
        'savedCount': post.stats.savedCount,
        'statsCount': post.stats.statsCount,
      },
    };
  }
}
