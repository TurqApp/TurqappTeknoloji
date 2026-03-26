part of 'tutoring_search_controller.dart';

class TutoringSearchController extends GetxController {
  static TutoringSearchController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringSearchController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringSearchController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TutoringSearchController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TutoringSearchController>(tag: tag);
  }

  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TextEditingController searchController = TextEditingController();
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;

  List<TutoringModel> _initialTutorings = [];

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }

  void resetSearch() => _handleResetSearch();
}
