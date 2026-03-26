part of 'tests_grid_controller.dart';

class TestsGridController extends GetxController {
  static TestsGridController ensure(
    TestsModel model, {
    Function? onUpdate,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestsGridController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestsGridController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestsGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestsGridController>(tag: tag);
  }

  final TestsModel model;
  final Function? onUpdate;

  final fullName = ''.obs;
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final secim = ''.obs;
  final totalYanit = 0.obs;
  final isFavorite = false.obs;
  final appStore = ''.obs;
  final googlePlay = ''.obs;
  final TestRepository _testRepository = TestRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  TestsGridController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() {
    checkIfFavorite();
    getUygulamaLinks();
    getUserData();
    getTotalYanit();
  }
}
