import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlight_model.dart';

class _CachedStoryHighlights {
  final List<StoryHighlightModel> items;
  final DateTime cachedAt;

  const _CachedStoryHighlights({
    required this.items,
    required this.cachedAt,
  });
}

class StoryHighlightsRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'story_highlights_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedStoryHighlights> _memory = {};

  static StoryHighlightsRepository ensure() {
    if (Get.isRegistered<StoryHighlightsRepository>()) {
      return Get.find<StoryHighlightsRepository>();
    }
    return Get.put(StoryHighlightsRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<List<StoryHighlightModel>> getHighlights(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return const <StoryHighlightModel>[];

    if (!forceRefresh) {
      final memory = _getFromMemory(uid, allowStale: false);
      if (preferCache && memory != null) return memory;
      final disk = await _getFromPrefsEntry(uid, allowStale: false);
      if (preferCache && disk != null) {
        _memory[uid] = _CachedStoryHighlights(
          items: disk.items.map(_clone).toList(growable: false),
          cachedAt: disk.cachedAt,
        );
        return disk.items.map(_clone).toList(growable: false);
      }
    }

    if (cacheOnly) return const <StoryHighlightModel>[];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .orderBy('order')
        .get();
    final list = snap.docs.map(StoryHighlightModel.fromDoc).toList();
    await setHighlights(uid, list);
    return list;
  }

  Future<void> setHighlights(
      String uid, List<StoryHighlightModel> items) async {
    if (uid.isEmpty) return;
    final cloned = items.map(_clone).toList(growable: false);
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedStoryHighlights(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map(
              (e) => {
                'id': e.id,
                'userId': e.userId,
                'title': e.title,
                'coverUrl': e.coverUrl,
                'storyIds': e.storyIds,
                'createdDate': e.createdAt.millisecondsSinceEpoch,
                'order': e.order,
              },
            )
            .toList(),
      }),
    );
  }

  Future<void> createHighlight(
    String uid,
    StoryHighlightModel model,
  ) async {
    if (uid.isEmpty || model.id.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(model.id)
        .set(model.toMap());
  }

  Future<void> addStoryToHighlight(
    String uid, {
    required String highlightId,
    required String storyId,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty || storyId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({
      'storyIds': FieldValue.arrayUnion([storyId]),
    });
  }

  Future<void> updateHighlight(
    String uid, {
    required String highlightId,
    required String title,
    required String coverUrl,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({
      'title': title,
      'coverUrl': coverUrl,
    });
  }

  Future<void> updateCoverUrl(
    String uid, {
    required String highlightId,
    required String coverUrl,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .update({'coverUrl': coverUrl});
  }

  Future<void> deleteHighlight(
    String uid, {
    required String highlightId,
  }) async {
    if (uid.isEmpty || highlightId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('highlights')
        .doc(highlightId)
        .delete();
  }

  Future<void> invalidate(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
  }

  List<StoryHighlightModel>? _getFromMemory(
    String uid, {
    required bool allowStale,
  }) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh && !allowStale) return null;
    return entry.items.map(_clone).toList(growable: false);
  }

  Future<_CachedStoryHighlights?> _getFromPrefsEntry(
    String uid, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final list =
          (decoded['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <= _ttl;
      if (!fresh && !allowStale) return null;
      return _CachedStoryHighlights(
        cachedAt: cachedAt,
        items: list
            .map(
              (e) => StoryHighlightModel(
                id: (e['id'] ?? '').toString(),
                userId: (e['userId'] ?? '').toString(),
                title: (e['title'] ?? '').toString(),
                coverUrl: (e['coverUrl'] ?? '').toString(),
                storyIds: (e['storyIds'] as List?)?.cast<String>() ??
                    const <String>[],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  (e['createdDate'] as num?)?.toInt() ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
                order: (e['order'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  StoryHighlightModel _clone(StoryHighlightModel item) => StoryHighlightModel(
        id: item.id,
        userId: item.userId,
        title: item.title,
        coverUrl: item.coverUrl,
        storyIds: List<String>.from(item.storyIds),
        createdAt: item.createdAt,
        order: item.order,
      );

  String _prefsKey(String uid) => '$_prefsPrefix:$uid';
}
