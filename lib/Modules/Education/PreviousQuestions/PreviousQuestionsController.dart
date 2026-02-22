import 'package:carousel_slider/carousel_options.dart';
import 'package:get/get.dart';

class PreviousQuestionsController extends GetxController {
  final Rx<CarouselOptions> options = CarouselOptions().obs;

  void setOptions(CarouselOptions carouselOptions) {
    options.value = carouselOptions;
  }
}
