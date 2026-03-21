import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/social_media_model.dart';

class _CachedSocialMediaLinks {
  final List<SocialMediaModel> items;
  final DateTime cachedAt;

  const _CachedSocialMediaLinks({
    required this.items,
    required this.cachedAt,
  });
}

class SocialMediaLinksRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'social_media_links_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedSocialMediaLinks> _memory = {};

  static SocialMediaLinksRepository? maybeFind() {
    final isRegistered = Get.isRegistered<SocialMediaLinksRepository>();
    if (!isRegistered) return null;
    return Get.find<SocialMediaLinksRepository>();
  }

  static SocialMediaLinksRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SocialMediaLinksRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<List<SocialMediaModel>> getLinks(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return const <SocialMediaModel>[];

    if (!forceRefresh) {
      final memory = _getFromMemory(uid, allowStale: false);
      if (preferCache && memory != null) {
        return memory;
      }
      final disk = await _getFromPrefsEntry(uid, allowStale: false);
      if (preferCache && disk != null) {
        _memory[uid] = _CachedSocialMediaLinks(
          items: _cloneItems(disk.items),
          cachedAt: disk.cachedAt,
        );
        return _cloneItems(disk.items);
      }
    }

    if (cacheOnly) return const <SocialMediaModel>[];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .orderBy('sira')
        .get();
    final list = snap.docs.map(SocialMediaModel.fromFirestore).toList();
    await setLinks(uid, list);
    return list;
  }

  Future<void> setLinks(String uid, List<SocialMediaModel> items) async {
    if (uid.isEmpty) return;
    final cloned = items
        .map(
          (e) => SocialMediaModel(
            docID: e.docID,
            title: e.title,
            url: e.url,
            sira: e.sira,
            logo: e.logo,
          ),
        )
        .toList(growable: false);
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedSocialMediaLinks(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map(
              (e) => {
                'docID': e.docID,
                'title': e.title,
                'url': e.url,
                'sira': e.sira,
                'logo': e.logo,
              },
            )
            .toList(),
      }),
    );
  }

  Future<void> saveLink(
    String uid, {
    required SocialMediaModel model,
  }) async {
    if (uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .doc(model.docID)
        .set({
      'title': model.title,
      'url': model.url,
      'sira': model.sira,
      'logo': model.logo,
    }, SetOptions(merge: true));

    final current = await getLinks(uid, preferCache: true, forceRefresh: false);
    final next = List<SocialMediaModel>.from(current)
      ..removeWhere((e) => e.docID == model.docID)
      ..add(model)
      ..sort((a, b) => a.sira.compareTo(b.sira));
    await setLinks(uid, next);
  }

  Future<void> deleteLink(String uid, String docId) async {
    if (uid.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .doc(docId)
        .delete();

    final current = await getLinks(uid, preferCache: true, forceRefresh: false);
    final next = current.where((e) => e.docID != docId).toList(growable: false);
    await setLinks(uid, next);
  }

  Future<void> reorderLinks(String uid, List<SocialMediaModel> items) async {
    if (uid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final normalized = <SocialMediaModel>[];
    for (int i = 0; i < items.length; i++) {
      final model = items[i];
      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('SosyalMedyaLinkleri')
            .doc(model.docID),
        {'sira': i},
      );
      normalized.add(
        SocialMediaModel(
          docID: model.docID,
          title: model.title,
          url: model.url,
          sira: i,
          logo: model.logo,
        ),
      );
    }
    await batch.commit();
    await setLinks(uid, normalized);
  }

  Future<void> invalidate(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(uid));
  }

  List<SocialMediaModel>? _getFromMemory(
    String uid, {
    required bool allowStale,
  }) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh && !allowStale) return null;
    return _cloneItems(entry.items);
  }

  Future<_CachedSocialMediaLinks?> _getFromPrefsEntry(
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
      return _CachedSocialMediaLinks(
        cachedAt: cachedAt,
        items: list
            .map(
              (e) => SocialMediaModel(
                docID: (e['docID'] ?? '').toString(),
                title: (e['title'] ?? '').toString(),
                url: (e['url'] ?? '').toString(),
                sira: (e['sira'] as num?) ?? 0,
                logo: (e['logo'] ?? '').toString(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  List<SocialMediaModel> _cloneItems(List<SocialMediaModel> items) {
    return items
        .map((e) => SocialMediaModel(
              docID: e.docID,
              title: e.title,
              url: e.url,
              sira: e.sira,
              logo: e.logo,
            ))
        .toList(growable: false);
  }

  String _prefsKey(String uid) => '$_prefsPrefix:$uid';
}
