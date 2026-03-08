import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
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

  Future<AdsFeatureFlagsService> init() async {
    await refreshOnce();
    _bind();
    return this;
  }

  Future<void> refreshOnce() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection(AdsCollections.systemFlags)
          .doc(AdsCollections.systemFlagsGlobalDoc);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set(AdFeatureFlags.defaults.toMap(), SetOptions(merge: true));
        flags.value = AdFeatureFlags.defaults;
        return;
      }
      flags.value = AdFeatureFlags.fromMap(doc.data());
    } catch (_) {
      flags.value = AdFeatureFlags.defaults;
    }
  }

  void _bind() {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection(AdsCollections.systemFlags)
        .doc(AdsCollections.systemFlagsGlobalDoc)
        .snapshots()
        .listen((event) {
      flags.value = AdFeatureFlags.fromMap(event.data());
    }, onError: (_) {
      flags.value = flags.value;
    });
  }

  Future<void> setFlags(AdFeatureFlags next) async {
    await FirebaseFirestore.instance
        .collection(AdsCollections.systemFlags)
        .doc(AdsCollections.systemFlagsGlobalDoc)
        .set(next.toMap(), SetOptions(merge: true));
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
