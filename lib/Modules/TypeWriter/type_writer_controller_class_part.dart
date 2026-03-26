part of 'type_writer_controller.dart';

class TypewriterController extends GetxController {
  static TypewriterController ensure({
    required String fullText,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TypewriterController(fullText),
      tag: tag,
      permanent: permanent,
    );
  }

  static TypewriterController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TypewriterController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TypewriterController>(tag: tag);
  }

  final String fullText;
  final RxString displayedText = ''.obs;
  int _currentIndex = 0;

  TypewriterController(this.fullText);

  @override
  void onInit() {
    super.onInit();
    _startTyping();
  }

  void _startTyping() async {
    while (_currentIndex < fullText.length) {
      await Future.delayed(const Duration(milliseconds: 100));
      displayedText.value += fullText[_currentIndex];
      _currentIndex++;
    }
  }
}
