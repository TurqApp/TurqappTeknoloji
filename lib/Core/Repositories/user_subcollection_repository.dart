import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_subcollection_repository_query_part.dart';
part 'user_subcollection_repository_action_part.dart';
part 'user_subcollection_repository_storage_part.dart';

class UserSubcollectionEntry {
  final String id;
  final Map<String, dynamic> data;

  const UserSubcollectionEntry({
    required this.id,
    required this.data,
  });
}

class _CachedUserSubcollection {
  final List<UserSubcollectionEntry> items;
  final DateTime cachedAt;

  const _CachedUserSubcollection({
    required this.items,
    required this.cachedAt,
  });
}

class UserSubcollectionRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'user_subcollection_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubcollection> _memory = {};

  static UserSubcollectionRepository? maybeFind() {
    final isRegistered = Get.isRegistered<UserSubcollectionRepository>();
    if (!isRegistered) return null;
    return Get.find<UserSubcollectionRepository>();
  }

  static UserSubcollectionRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UserSubcollectionRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<List<UserSubcollectionEntry>> getEntries(
    String uid, {
    required String subcollection,
    String? orderByField,
    bool descending = true,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _getEntriesImpl(
        uid,
        subcollection: subcollection,
        orderByField: orderByField,
        descending: descending,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> setEntries(
    String uid, {
    required String subcollection,
    required List<UserSubcollectionEntry> items,
  }) =>
      _setEntriesImpl(
        uid,
        subcollection: subcollection,
        items: items,
      );

  Future<UserSubcollectionEntry?> getEntry(
    String uid, {
    required String subcollection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _getEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<void> invalidate(
    String uid, {
    required String subcollection,
  }) =>
      _invalidateImpl(
        uid,
        subcollection: subcollection,
      );

  Future<void> upsertEntry(
    String uid, {
    required String subcollection,
    required String docId,
    required Map<String, dynamic> data,
  }) =>
      _upsertEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
        data: data,
      );

  Future<void> deleteEntry(
    String uid, {
    required String subcollection,
    required String docId,
  }) =>
      _deleteEntryImpl(
        uid,
        subcollection: subcollection,
        docId: docId,
      );
}
