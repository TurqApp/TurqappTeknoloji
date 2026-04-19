import 'dart:async';

import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';
import 'package:turqappv2/Modules/Profile/Settings/settings_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

Map<String, bool> normalizePasajVisibilitySnapshot(
  Map<String, bool>? source, {
  bool defaultValue = true,
}) {
  return <String, bool>{
    for (final tabId in pasajTabs) tabId: source?[tabId] ?? defaultValue,
  };
}

Map<String, bool> readPasajAdminVisibilitySnapshot(
  Map<String, dynamic>? data,
) {
  return <String, bool>{
    for (final tabId in pasajTabs)
      tabId: data?[pasajAdminConfigKey(tabId)] is bool
          ? data![pasajAdminConfigKey(tabId)] as bool
          : true,
  };
}

Map<String, bool> resolveEffectivePasajVisibilitySnapshot({
  Map<String, bool>? localVisibility,
  Map<String, bool>? adminVisibility,
}) {
  final normalizedLocal = normalizePasajVisibilitySnapshot(localVisibility);
  final normalizedAdmin = normalizePasajVisibilitySnapshot(adminVisibility);
  return <String, bool>{
    for (final tabId in pasajTabs)
      tabId: normalizedLocal[tabId]! && normalizedAdmin[tabId]!,
  };
}

bool _shouldUseRemotePasajVisibility() {
  return CurrentUserService.instance.hasAuthUser;
}

Future<Map<String, bool>> loadEffectivePasajVisibility({
  bool preferCache = true,
  bool forceRefresh = false,
}) async {
  final local = await loadPasajVisibilitySnapshot();
  if (!_shouldUseRemotePasajVisibility()) {
    return resolveEffectivePasajVisibilitySnapshot(
      localVisibility: local,
    );
  }
  final data = await ensureConfigRepository().getAdminConfigDoc(
    'pasaj',
    preferCache: preferCache,
    forceRefresh: forceRefresh,
  );
  return resolveEffectivePasajVisibilitySnapshot(
    localVisibility: local,
    adminVisibility: readPasajAdminVisibilitySnapshot(data),
  );
}

Future<bool> isPasajTabEnabled(
  String tabId, {
  bool preferCache = true,
  bool forceRefresh = false,
}) async {
  if (!pasajTabs.contains(tabId)) return true;
  final localVisible = await isPasajTabVisibleLocally(tabId);
  if (!localVisible) return false;
  if (!_shouldUseRemotePasajVisibility()) {
    return true;
  }
  final data = await ensureConfigRepository().getAdminConfigDoc(
    'pasaj',
    preferCache: preferCache,
    forceRefresh: forceRefresh,
  );
  final adminVisibility = readPasajAdminVisibilitySnapshot(data);
  return adminVisibility[tabId] ?? true;
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
