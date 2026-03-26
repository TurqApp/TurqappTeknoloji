part of 'slider_repository.dart';

class SliderRepository extends _SliderRepositoryBase {
  SliderRepository({super.firestore});

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
