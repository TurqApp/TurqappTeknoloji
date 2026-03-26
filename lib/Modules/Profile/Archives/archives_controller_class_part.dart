part of 'archives_controller.dart';

class ArchiveController extends GetxController {
  static ArchiveController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ArchiveController());
  }

  static ArchiveController? maybeFind() {
    final isRegistered = Get.isRegistered<ArchiveController>();
    if (!isRegistered) return null;
    return Get.find<ArchiveController>();
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final scrollController = ScrollController();

  final RxList<PostsModel> list = <PostsModel>[].obs;
  final RxBool isLoading = true.obs;
  final Map<String, GlobalKey> _agendaKeys = {};
  final currentVisibleIndex = RxInt(-1);
  int? lastCenteredIndex;
  final centeredIndex = 0.obs;
  String? _pendingCenteredDocId;
  StreamSubscription<User?>? _authSub;
  String? _currentUserId;

  String get _resolvedCurrentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> fetchData({bool silent = false}) async {
    await _ArchiveControllerDataPart(this).fetchArchiveData(silent: silent);
  }

  @override
  void onInit() {
    super.onInit();
    _ArchiveControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _ArchiveControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
