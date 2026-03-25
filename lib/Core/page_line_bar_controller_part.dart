part of 'page_line_bar.dart';

class PageLineBarController extends GetxController {
  static PageLineBarController ensure({
    required String pageName,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PageLineBarController(pageName: pageName),
      tag: tag,
      permanent: permanent,
    );
  }

  static PageLineBarController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PageLineBarController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PageLineBarController>(tag: tag);
  }

  final String pageName;
  PageLineBarController({required this.pageName});
  final _state = _PageLineBarControllerState();

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
