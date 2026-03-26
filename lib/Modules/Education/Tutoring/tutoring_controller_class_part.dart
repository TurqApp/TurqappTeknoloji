part of 'tutoring_controller.dart';

class TutoringController extends GetxController {
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchPreviewController = TextEditingController();
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var searchResults = <TutoringModel>[].obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<CachedResource<List<TutoringModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;
  int _currentPage = 1;

  static const int _pageSize = 30;
  bool get hasActiveSearch => _hasActiveTutoringSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleTutoringControllerInit(this);
  }

  @override
  void onClose() {
    _handleTutoringControllerClose(this);
    super.onClose();
  }
}
