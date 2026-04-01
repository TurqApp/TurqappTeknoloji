part of 'slider_repository_library.dart';

Future<SliderRemoteData> _fetchSliderRemoteData(
  _SliderRepositoryBase repository,
  String sliderId,
) async {
  final sliderRef = repository._firestore.collection('sliders').doc(sliderId);
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
