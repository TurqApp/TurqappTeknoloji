part of 'slider_repository_library.dart';

class SliderRepository extends _SliderRepositoryBase {
  SliderRepository({super.firestore});

  Future<SliderRemoteData> fetchSlider(String sliderId) =>
      _fetchSliderRemoteData(this, sliderId);
}
