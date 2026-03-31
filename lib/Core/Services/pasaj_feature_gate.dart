import 'dart:async';

import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';

bool _readPasajAdminVisibility(
  Map<String, dynamic>? data,
  String tabId,
) {
  if (data == null || data.isEmpty) return true;
  final raw = data[pasajAdminConfigKey(tabId)];
  return raw is bool ? raw : true;
}

Future<Map<String, bool>> loadEffectivePasajVisibility({
  bool preferCache = true,
  bool forceRefresh = false,
}) async {
  final local = await loadPasajVisibilitySnapshot();
  final data = await ensureConfigRepository().getAdminConfigDoc(
    'pasaj',
    preferCache: preferCache,
    forceRefresh: forceRefresh,
  );
  return <String, bool>{
    for (final tabId in pasajTabs)
      tabId: (local[tabId] ?? true) && _readPasajAdminVisibility(data, tabId),
  };
}

Future<bool> isPasajTabEnabled(
  String tabId, {
  bool preferCache = true,
  bool forceRefresh = false,
}) async {
  if (!pasajTabs.contains(tabId)) return true;
  final localVisible = await isPasajTabVisibleLocally(tabId);
  if (!localVisible) return false;
  final data = await ensureConfigRepository().getAdminConfigDoc(
    'pasaj',
    preferCache: preferCache,
    forceRefresh: forceRefresh,
  );
  return _readPasajAdminVisibility(data, tabId);
}

CachedResource<T> pasajDisabledResource<T>(T data) {
  return CachedResource<T>(
    data: data,
    hasLocalSnapshot: false,
    isRefreshing: false,
    isStale: false,
    hasLiveError: false,
    snapshotAt: null,
    source: CachedResourceSource.none,
  );
}

Stream<CachedResource<T>> pasajDisabledStream<T>(T data) async* {
  yield pasajDisabledResource<T>(data);
}
