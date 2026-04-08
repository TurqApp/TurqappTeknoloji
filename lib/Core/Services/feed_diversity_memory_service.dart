import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/posts_model.dart';

class FeedDiversityMemoryService extends GetxService {
  static const Duration startupHeadWindow = Duration(days: 3);
  static const Duration weeklyWatchWindow = Duration(days: 7);
  static const Duration _watchWriteCooldown = Duration(hours: 12);

  static const String _startupHeadKey = 'feed_diversity_startup_heads_v1';
  static const String _weeklyWatchKey = 'feed_diversity_weekly_watches_v1';
  static const int _maxStartupHeadRecords = 120;
  static const int _maxWeeklyWatchRecords = 320;

  SharedPreferences? _prefs;
  bool _ready = false;
  Future<void>? _readyFuture;

  final List<_FeedDiversityRecord> _startupHeadRecords =
      <_FeedDiversityRecord>[];
  final List<_FeedDiversityRecord> _weeklyWatchRecords =
      <_FeedDiversityRecord>[];
  final Set<String> _pendingWeeklyWatchDocIds = <String>{};

  static FeedDiversityMemoryService? maybeFind() {
    final isRegistered = Get.isRegistered<FeedDiversityMemoryService>();
    if (!isRegistered) return null;
    return Get.find<FeedDiversityMemoryService>();
  }

  static FeedDiversityMemoryService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FeedDiversityMemoryService(), permanent: true);
  }

  Future<void> ensureReady() {
    final existing = _readyFuture;
    if (existing != null) return existing;
    final future = _load();
    _readyFuture = future;
    return future;
  }

  bool get isReady => _ready;

  Set<String> startupHeadPenaltyDocIds({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(startupHeadWindow);
    return _startupHeadRecords
        .where((entry) => entry.at.isAfter(cutoff))
        .map((entry) => entry.docId)
        .where((docId) => docId.isNotEmpty)
        .toSet();
  }

  Set<String> startupHeadPenaltyFloodRootIds({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(startupHeadWindow);
    return _startupHeadRecords
        .where((entry) => entry.at.isAfter(cutoff))
        .map((entry) => entry.floodRootId)
        .where((rootId) => rootId.isNotEmpty)
        .toSet();
  }

  Set<String> weeklyWatchedPenaltyDocIds({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(weeklyWatchWindow);
    return _weeklyWatchRecords
        .where((entry) => entry.at.isAfter(cutoff))
        .map((entry) => entry.docId)
        .where((docId) => docId.isNotEmpty)
        .toSet();
  }

  Set<String> weeklyWatchedFloodRootIds({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(weeklyWatchWindow);
    return _weeklyWatchRecords
        .where((entry) => entry.at.isAfter(cutoff))
        .map((entry) => entry.floodRootId)
        .where((rootId) => rootId.isNotEmpty)
        .toSet();
  }

  void rememberStartupHead(Iterable<PostsModel> posts) {
    unawaited(_rememberStartupHead(posts));
  }

  void noteWatchedPost(
    PostsModel post, {
    required int currentSegment,
  }) {
    if (!post.hasPlayableVideo || currentSegment < 3) return;
    final docId = post.docID.trim();
    if (docId.isEmpty) return;
    if (_pendingWeeklyWatchDocIds.contains(docId)) return;
    final now = DateTime.now();
    if (_hasRecentWeeklyWatch(docId, now: now)) return;
    _pendingWeeklyWatchDocIds.add(docId);
    unawaited(_rememberWatchedPost(post, queuedAt: now));
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _startupHeadRecords
      ..clear()
      ..addAll(
        _decodeRecords(_prefs!.getString(_startupHeadKey)),
      );
    _weeklyWatchRecords
      ..clear()
      ..addAll(
        _decodeRecords(_prefs!.getString(_weeklyWatchKey)),
      );
    _prune();
    _ready = true;
  }

  Future<void> _rememberStartupHead(Iterable<PostsModel> posts) async {
    await ensureReady();
    final now = DateTime.now();
    for (final post in posts.take(20)) {
      final record = _recordForPost(post, at: now);
      _upsertRecord(
        _startupHeadRecords,
        record,
        maxCount: _maxStartupHeadRecords,
      );
    }
    await _persistStartupHead();
  }

  Future<void> _rememberWatchedPost(
    PostsModel post, {
    required DateTime queuedAt,
  }) async {
    final docId = post.docID.trim();
    try {
      await ensureReady();
      if (_hasRecentWeeklyWatch(docId, now: queuedAt)) return;
      final record = _recordForPost(post, at: queuedAt);
      _upsertRecord(
        _weeklyWatchRecords,
        record,
        maxCount: _maxWeeklyWatchRecords,
      );
      await _persistWeeklyWatch();
    } finally {
      _pendingWeeklyWatchDocIds.remove(docId);
    }
  }

  bool _hasRecentWeeklyWatch(
    String docId, {
    required DateTime now,
  }) {
    for (final entry in _weeklyWatchRecords) {
      if (entry.docId != docId) continue;
      if (now.difference(entry.at) < _watchWriteCooldown) {
        return true;
      }
      return false;
    }
    return false;
  }

  _FeedDiversityRecord _recordForPost(
    PostsModel post, {
    required DateTime at,
  }) {
    final docId = post.docID.trim();
    final rootId = _resolveFloodRootId(post);
    return _FeedDiversityRecord(
      docId: docId,
      floodRootId: rootId,
      at: at,
    );
  }

  String _resolveFloodRootId(PostsModel post) {
    if (!post.isFloodSeriesContent) return '';
    final mainFlood = post.mainFlood.trim();
    if (mainFlood.isNotEmpty) {
      return mainFlood;
    }
    if (post.isFloodSeriesRoot) {
      return post.docID.trim();
    }
    return post.docID.trim().replaceFirst(RegExp(r'_\d+$'), '');
  }

  void _upsertRecord(
    List<_FeedDiversityRecord> records,
    _FeedDiversityRecord next, {
    required int maxCount,
  }) {
    records.removeWhere((entry) => entry.docId == next.docId);
    records.add(next);
    records.sort((a, b) => b.at.compareTo(a.at));
    if (records.length > maxCount) {
      records.removeRange(maxCount, records.length);
    }
  }

  void _prune() {
    final now = DateTime.now();
    final startupCutoff = now.subtract(startupHeadWindow);
    final watchCutoff = now.subtract(weeklyWatchWindow);
    _startupHeadRecords
        .removeWhere((entry) => entry.at.isBefore(startupCutoff));
    _weeklyWatchRecords.removeWhere((entry) => entry.at.isBefore(watchCutoff));
  }

  Future<void> _persistStartupHead() async {
    final prefs = _prefs;
    if (prefs == null) return;
    _prune();
    await prefs.setString(
      _startupHeadKey,
      jsonEncode(_startupHeadRecords.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> _persistWeeklyWatch() async {
    final prefs = _prefs;
    if (prefs == null) return;
    _prune();
    await prefs.setString(
      _weeklyWatchKey,
      jsonEncode(_weeklyWatchRecords.map((entry) => entry.toJson()).toList()),
    );
  }

  List<_FeedDiversityRecord> _decodeRecords(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <_FeedDiversityRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <_FeedDiversityRecord>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (entry) => _FeedDiversityRecord.fromJson(
              Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
            ),
          )
          .where((entry) => entry.docId.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return const <_FeedDiversityRecord>[];
    }
  }
}

class _FeedDiversityRecord {
  const _FeedDiversityRecord({
    required this.docId,
    required this.floodRootId,
    required this.at,
  });

  final String docId;
  final String floodRootId;
  final DateTime at;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'docId': docId,
        'floodRootId': floodRootId,
        'at': at.millisecondsSinceEpoch,
      };

  factory _FeedDiversityRecord.fromJson(Map<String, dynamic> json) {
    final atMs = (json['at'] as num?)?.toInt() ?? 0;
    return _FeedDiversityRecord(
      docId: (json['docId'] ?? '').toString().trim(),
      floodRootId: (json['floodRootId'] ?? '').toString().trim(),
      at: atMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(atMs)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
