part of 'ads_feature_flags_service.dart';

class AdsFeatureFlagsService extends GetxService {
  static AdsFeatureFlagsService? maybeFind() {
    final isRegistered = Get.isRegistered<AdsFeatureFlagsService>();
    if (!isRegistered) return null;
    return Get.find<AdsFeatureFlagsService>();
  }

  static AdsFeatureFlagsService ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      AdsFeatureFlagsService(),
      permanent: permanent,
    );
  }

  static AdsFeatureFlagsService get to => ensure();

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

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
