part of 'slider_repository_library.dart';

SliderRepository? maybeFindSliderRepository() =>
    Get.isRegistered<SliderRepository>() ? Get.find<SliderRepository>() : null;

SliderRepository ensureSliderRepository() =>
    maybeFindSliderRepository() ?? Get.put(SliderRepository(), permanent: true);
