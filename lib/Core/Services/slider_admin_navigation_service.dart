import 'package:get/get.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';

class SliderAdminNavigationService {
  const SliderAdminNavigationService();

  Future<void> openSliderAdmin({
    required String sliderId,
    required String title,
  }) async {
    await Get.to(
      () => SliderAdminView(
        sliderId: sliderId,
        title: title,
      ),
    );
  }
}
