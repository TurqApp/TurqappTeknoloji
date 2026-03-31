part of 'admob_unit_config_service.dart';

Future<void> _initInternalAdmobConfig(AdmobUnitConfigService service) async {
  try {
    final currentData = await ensureConfigRepository().getAdminConfigDoc(
      AdsCollections.admobUnitsDoc,
      preferCache: true,
      ttl: const Duration(hours: 6),
    );
    if (currentData != null && currentData.isNotEmpty) {
      service._config = _AdmobUnitConfig.fromMap(currentData);
      await _persistResolvedAdmobConfig(service, service._config.toMap());
    } else {
      final legacyData = await ensureConfigRepository().getAdminConfigDoc(
        _legacyDocId,
        preferCache: true,
        ttl: const Duration(hours: 6),
      );
      if (legacyData != null && legacyData.isNotEmpty) {
        service._config = _AdmobUnitConfig.fromMap(legacyData);
        await _persistResolvedAdmobConfig(service, service._config.toMap());
      } else {
        await _persistResolvedAdmobConfig(service, service._config.toMap());
      }
    }
  } catch (_) {
    service._config = _AdmobUnitConfig.defaults;
  }

  service._sub?.cancel();
  service._sub = ensureConfigRepository()
      .watchAdminConfigDoc(
    AdsCollections.admobUnitsDoc,
    ttl: const Duration(hours: 6),
  )
      .listen((data) {
    if (data.isEmpty) return;
    service._config = _AdmobUnitConfig.fromMap(data);
  });
  service._initialized = true;
}

Future<void> _persistResolvedAdmobConfig(
  AdmobUnitConfigService service,
  Map<String, dynamic> data,
) async {
  try {
    await ensureConfigRepository().putAdminConfigDoc(
      AdsCollections.admobUnitsDoc,
      data,
    );
  } catch (_) {}
}

String _nextAdmobUnitId(
  AdmobUnitConfigService service, {
  required List<String> ids,
  required String cursorKey,
  required String fallback,
}) {
  if (ids.isEmpty) return fallback;
  final currentIndex = service._cursorByKey[cursorKey] ?? 0;
  final next = ids[currentIndex % ids.length];
  service._cursorByKey[cursorKey] = (currentIndex + 1) % ids.length;
  return next;
}

void _disposeAdmobConfigRuntime(AdmobUnitConfigService service) {
  service._sub?.cancel();
}
