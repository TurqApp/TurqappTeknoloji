part of 'slider_repository_library.dart';

SliderRepository? maybeFindSliderRepository() {
  final isRegistered = Get.isRegistered<SliderRepository>();
  if (!isRegistered) return null;
  return Get.find<SliderRepository>();
}

SliderRepository ensureSliderRepository() {
  final existing = maybeFindSliderRepository();
  if (existing != null) return existing;
  return Get.put(SliderRepository(), permanent: true);
}
