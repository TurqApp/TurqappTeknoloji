part of 'category_based_answer_key_controller.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  static CategoryBasedAnswerKeyController ensure(
    String sinavTuru, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CategoryBasedAnswerKeyController(sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static CategoryBasedAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CategoryBasedAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CategoryBasedAnswerKeyController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String sinavTuru;
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final search = TextEditingController();
  final isLoading = true.obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  CategoryBasedAnswerKeyController(this.sinavTuru);

  @override
  void onInit() {
    super.onInit();
    _handleCategoryAnswerKeyInit();
  }

  @override
  void onClose() {
    _handleCategoryAnswerKeyClose();
    super.onClose();
  }
}
