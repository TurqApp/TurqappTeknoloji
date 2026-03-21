import 'package:carousel_slider/carousel_options.dart';
import 'package:get/get.dart';

class PreviousQuestionsController extends GetxController {
  static PreviousQuestionsController ensure(
      {String? tag, bool permanent = false}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PreviousQuestionsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PreviousQuestionsController? maybeFind({String? tag}) {
    if (!Get.isRegistered<PreviousQuestionsController>(tag: tag)) return null;
    return Get.find<PreviousQuestionsController>(tag: tag);
  }

  final Rx<CarouselOptions> options = CarouselOptions().obs;

  void setOptions(CarouselOptions carouselOptions) {
    options.value = carouselOptions;
  }
}
