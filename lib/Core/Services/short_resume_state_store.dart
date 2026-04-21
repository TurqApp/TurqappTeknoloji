import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Models/posts_model.dart';

int _shortResumeAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _shortResumeAsBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1';
}

class ShortResumeState {
  ShortResumeState({
    required this.manifestId,
    required this.cursorSlotIndex,
    required this.cursorItemIndex,
    required this.hasMore,
    required this.savedAtMs,
    required List<PostsModel> remainingPosts,
  }) : remainingPosts = List<PostsModel>.from(remainingPosts);

  final String manifestId;
  final int cursorSlotIndex;
  final int cursorItemIndex;
  final bool hasMore;
  final int savedAtMs;
  final List<PostsModel> remainingPosts;

  bool get hasCursor =>
      manifestId.trim().isNotEmpty &&
      cursorSlotIndex >= 0 &&
      cursorItemIndex >= 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'manifestId': manifestId,
      'cursorSlotIndex': cursorSlotIndex,
      'cursorItemIndex': cursorItemIndex,
      'hasMore': hasMore,
      'savedAtMs': savedAtMs,
      'remainingPosts': remainingPosts
          .map((post) => <String, dynamic>{
                'docId': post.docID,
                'data': post.toMap(),
              })
          .toList(growable: false),
    };
  }

  factory ShortResumeState.fromJson(Map<String, dynamic> json) {
    final posts = <PostsModel>[];
    final remainingPostsRaw = json['remainingPosts'];
    if (remainingPostsRaw is List) {
      for (final raw in remainingPostsRaw) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
        final docId = (map['docId'] ?? '').toString().trim();
        final data = map['data'];
        if (docId.isEmpty || data is! Map) continue;
        try {
          posts.add(
            PostsModel.fromMap(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            ),
          );
        } catch (_) {}
      }
    }
    return ShortResumeState(
      manifestId: (json['manifestId'] ?? '').toString().trim(),
      cursorSlotIndex: _shortResumeAsInt(json['cursorSlotIndex']),
      cursorItemIndex: _shortResumeAsInt(json['cursorItemIndex']),
      hasMore: _shortResumeAsBool(json['hasMore']),
      savedAtMs: _shortResumeAsInt(json['savedAtMs']),
      remainingPosts: posts,
    );
  }
}

class ShortResumeStateStore extends GetxService {
  ShortResumeStateStore({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const int _schemaVersion = 1;
  static const Duration defaultFreshWindow = Duration(hours: 18);

  final Future<Directory> Function() _directoryProvider;

  Directory? _directory;

  Future<Directory> _rootDirectory() async {
    final existing = _directory;
    if (existing != null) return existing;
    final supportDir = await _directoryProvider();
    final directory = Directory('${supportDir.path}/short_resume_state_v1');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _directory = directory;
    return directory;
  }

  Future<ShortResumeState?> load({
    required String userId,
    Duration? maxAge,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final file = await _stateFile(normalizedUserId);
    if (!await file.exists()) return null;
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        await clear(userId: normalizedUserId);
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clear(userId: normalizedUserId);
        return null;
      }
      final map = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
      if (_shortResumeAsInt(map['schemaVersion']) != _schemaVersion) {
        await clear(userId: normalizedUserId);
        return null;
      }
      final state = ShortResumeState.fromJson(map);
      final savedAtMs = state.savedAtMs;
      if (savedAtMs <= 0) {
        await clear(userId: normalizedUserId);
        return null;
      }
      final allowedAge = maxAge ?? defaultFreshWindow;
      final ageMs = DateTime.now().millisecondsSinceEpoch - savedAtMs;
      if (ageMs < 0 || ageMs > allowedAge.inMilliseconds) {
        await clear(userId: normalizedUserId);
        return null;
      }
      if (state.remainingPosts.isEmpty && !state.hasCursor) {
        await clear(userId: normalizedUserId);
        return null;
      }
      return state;
    } catch (_) {
      await clear(userId: normalizedUserId);
      return null;
    }
  }

  Future<void> save({
    required String userId,
    required ShortResumeState state,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    if (state.remainingPosts.isEmpty && !state.hasCursor) {
      await clear(userId: normalizedUserId);
      return;
    }
    final file = await _stateFile(normalizedUserId);
    final payload = jsonEncode(
      <String, dynamic>{
        'schemaVersion': _schemaVersion,
        ...state.toJson(),
      },
    );
    final tmp = File('${file.path}.tmp');
    await file.parent.create(recursive: true);
    await tmp.writeAsString(payload, flush: true);
    try {
      await tmp.rename(file.path);
    } on FileSystemException {
      await file.writeAsString(payload, flush: true);
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }
  }

  Future<void> clear({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    final file = await _stateFile(normalizedUserId);
    if (await file.exists()) {
      await file.delete();
    }
    final tmp = File('${file.path}.tmp');
    if (await tmp.exists()) {
      await tmp.delete();
    }
  }

  Future<File> _stateFile(String userId) async {
    final directory = await _rootDirectory();
    return File('${directory.path}/${_safeSegment(userId)}.json');
  }

  String _safeSegment(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

ShortResumeStateStore? maybeFindShortResumeStateStore() {
  final isRegistered = Get.isRegistered<ShortResumeStateStore>();
  if (!isRegistered) return null;
  return Get.find<ShortResumeStateStore>();
}

ShortResumeStateStore ensureShortResumeStateStore() {
  final existing = maybeFindShortResumeStateStore();
  if (existing != null) return existing;
  return Get.put(ShortResumeStateStore(), permanent: true);
}
