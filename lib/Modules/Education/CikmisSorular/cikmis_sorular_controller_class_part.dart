part of 'cikmis_sorular_controller.dart';

class CikmisSorularController extends GetxController {
  static CikmisSorularController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularController(), permanent: permanent);
  }

  static CikmisSorularController? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularController>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularController>();
  }

  final CikmisSorularSnapshotRepository _snapshotRepository =
      CikmisSorularSnapshotRepository.ensure();

  final covers = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final scrollController = ScrollController();
  final scrollOffset = 0.0.obs;
  final pendingScrollReset = false.obs;

  Timer? _searchDebounce;
  int _searchToken = 0;
  StreamSubscription<CachedResource<List<Map<String, dynamic>>>>?
      _homeSnapshotSub;

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

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

  void requestScrollReset() => _requestScrollReset();
}
