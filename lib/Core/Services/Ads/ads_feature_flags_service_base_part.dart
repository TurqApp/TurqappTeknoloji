part of 'ads_feature_flags_service.dart';

abstract class _AdsFeatureFlagsServiceBase extends GetxService {
  final Rx<AdFeatureFlags> flags = AdFeatureFlags.defaults.obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  DocumentReference<Map<String, dynamic>> get _primaryRef =>
      AppFirestore.instance
          .collection(AdsCollections.adminConfig)
          .doc(AdsCollections.adsFlagsDoc);

  DocumentReference<Map<String, dynamic>> get _legacyRef =>
      AppFirestore.instance
          .collection(AdsCollections.legacySystemFlags)
          .doc(AdsCollections.systemFlagsGlobalDoc);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

class AdsFeatureFlagsService extends _AdsFeatureFlagsServiceBase {}
