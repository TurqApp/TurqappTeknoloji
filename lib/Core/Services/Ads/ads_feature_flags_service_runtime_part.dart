part of 'ads_feature_flags_service.dart';

extension AdsFeatureFlagsServiceRuntimePart on AdsFeatureFlagsService {
  Future<AdsFeatureFlagsService> init() async {
    await refreshOnce();
    _bind();
    return this;
  }

  Future<void> refreshOnce() async {
    try {
      final primaryDoc = await ensureConfigRepository().getAdminConfigDoc(
        AdsCollections.adsFlagsDoc,
        preferCache: true,
      );
      if (primaryDoc != null) {
        flags.value = AdFeatureFlags.fromMap(primaryDoc);
        return;
      }

      final legacyDoc = await _legacyRef.get();
      if (legacyDoc.exists) {
        final migrated = AdFeatureFlags.fromMap(legacyDoc.data());
        await _primaryRef.set(migrated.toMap(), SetOptions(merge: true));
        flags.value = migrated;
        return;
      }

      await _primaryRef.set(
        AdFeatureFlags.defaults.toMap(),
        SetOptions(merge: true),
      );
      await ensureConfigRepository().putAdminConfigDoc(
        AdsCollections.adsFlagsDoc,
        AdFeatureFlags.defaults.toMap(),
      );
      flags.value = AdFeatureFlags.defaults;
    } catch (_) {
      flags.value = AdFeatureFlags.defaults;
    }
  }

  void _bind() {
    _sub?.cancel();
    _sub = _primaryRef.snapshots().listen((event) {
      flags.value = AdFeatureFlags.fromMap(event.data());
    }, onError: (_) {
      flags.value = flags.value;
    });
  }

  Future<void> setFlags(AdFeatureFlags next) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_primaryRef, next.toMap(), SetOptions(merge: true));
    batch.delete(_legacyRef);
    await batch.commit();
    await ensureConfigRepository().putAdminConfigDoc(
      AdsCollections.adsFlagsDoc,
      next.toMap(),
    );
    flags.value = next;
  }

  bool get isInfrastructureEnabled => flags.value.adsInfrastructureEnabled;
  bool get isAdminPanelEnabled => flags.value.adsAdminPanelEnabled;
  bool get isDeliveryEnabled => flags.value.adsDeliveryEnabled;
  bool get isPublicVisible => flags.value.adsPublicVisibilityEnabled;
  bool get isPreviewEnabled => flags.value.adsPreviewModeEnabled;
}
