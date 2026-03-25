import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/social_media_model.dart';

part 'social_media_links_repository_query_part.dart';
part 'social_media_links_repository_action_part.dart';
part 'social_media_links_repository_storage_part.dart';

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
  }) =>
      _getLinksImpl(
        uid,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<bool> hasFreshCacheEntry(String uid) => _hasFreshCacheEntryImpl(uid);

  Future<void> setLinks(String uid, List<SocialMediaModel> items) =>
      _setLinksImpl(uid, items);

  Future<void> saveLink(
    String uid, {
    required SocialMediaModel model,
  }) =>
      _saveLinkImpl(uid, model: model);

  Future<void> deleteLink(String uid, String docId) =>
      _deleteLinkImpl(uid, docId);

  Future<void> reorderLinks(String uid, List<SocialMediaModel> items) =>
      _reorderLinksImpl(uid, items);

  Future<void> invalidate(String uid) => _invalidateImpl(uid);
}
