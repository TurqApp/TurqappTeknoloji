import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';
import 'package:turqappv2/Models/Ads/ad_feature_flags.dart';

class AdsFeatureFlagsService extends GetxService {
  static AdsFeatureFlagsService get to {
    if (Get.isRegistered<AdsFeatureFlagsService>()) {
      return Get.find<AdsFeatureFlagsService>();
    }
    return Get.put(AdsFeatureFlagsService());
  }

  final Rx<AdFeatureFlags> flags = AdFeatureFlags.defaults.obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  DocumentReference<Map<String, dynamic>> get _primaryRef =>
      FirebaseFirestore.instance
          .collection(AdsCollections.adminConfig)
          .doc(AdsCollections.adsFlagsDoc);

  DocumentReference<Map<String, dynamic>> get _legacyRef =>
      FirebaseFirestore.instance
          .collection(AdsCollections.legacySystemFlags)
          .doc(AdsCollections.systemFlagsGlobalDoc);

  Future<AdsFeatureFlagsService> init() async {
    await refreshOnce();
    _bind();
    return this;
  }

  Future<void> refreshOnce() async {
    try {
      final primaryDoc = await ConfigRepository.ensure().getAdminConfigDoc(
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
      await ConfigRepository.ensure().putAdminConfigDoc(
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
    await ConfigRepository.ensure().putAdminConfigDoc(
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

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
