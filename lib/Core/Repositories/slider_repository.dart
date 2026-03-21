import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SliderRepository extends GetxService {
  SliderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static SliderRepository? maybeFind() {
    if (!Get.isRegistered<SliderRepository>()) return null;
    return Get.find<SliderRepository>();
  }

  static SliderRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SliderRepository(), permanent: true);
  }

  static SliderRepository ensure() {
    return _ensureService();
  }

  Future<SliderRemoteData> fetchSlider(String sliderId) async {
    final sliderRef = _firestore.collection('sliders').doc(sliderId);
    final results = await Future.wait([
      sliderRef.get(const GetOptions(source: Source.serverAndCache)),
      sliderRef
          .collection('items')
          .orderBy('order')
          .get(const GetOptions(source: Source.serverAndCache)),
    ]);

    return SliderRemoteData(
      meta: results[0] as DocumentSnapshot<Map<String, dynamic>>,
      items: results[1] as QuerySnapshot<Map<String, dynamic>>,
    );
  }
}

class SliderRemoteData {
  const SliderRemoteData({
    required this.meta,
    required this.items,
  });

  final DocumentSnapshot<Map<String, dynamic>> meta;
  final QuerySnapshot<Map<String, dynamic>> items;
}
