part of 'slider_repository.dart';

class SliderRepository extends GetxService {
  SliderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static SliderRepository? maybeFind() {
    final isRegistered = Get.isRegistered<SliderRepository>();
    if (!isRegistered) return null;
    return Get.find<SliderRepository>();
  }

  static SliderRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SliderRepository(), permanent: true);
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
