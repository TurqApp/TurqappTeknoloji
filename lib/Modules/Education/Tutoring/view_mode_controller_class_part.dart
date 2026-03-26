part of 'view_mode_controller.dart';

class ViewModeController extends GetxController {
  static ViewModeController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ViewModeController(), permanent: permanent);
  }

  static ViewModeController? maybeFind() {
    final isRegistered = Get.isRegistered<ViewModeController>();
    if (!isRegistered) return null;
    return Get.find<ViewModeController>();
  }

  static const String _viewModePrefKeyPrefix = 'pasaj_tutoring_view_mode';
  var isGridView = true.obs;
  final RxBool isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_ViewModeControllerRuntimePart(this).restoreViewMode());
  }

  void toggleView() => _ViewModeControllerRuntimePart(this).toggleView();
}
