import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  String _viewModeKeyFor(String uid) => '${_viewModePrefKeyPrefix}_$uid';

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreViewMode());
  }

  Future<void> _restoreViewMode() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isGridView.value = true;
      isReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      isGridView.value = prefs.getBool(_viewModeKeyFor(uid)) ?? true;
    } catch (_) {
      isGridView.value = true;
    } finally {
      isReady.value = true;
    }
  }

  Future<void> _persistViewMode() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_viewModeKeyFor(uid), isGridView.value);
    } catch (_) {}
  }

  void toggleView() {
    isGridView.value = !isGridView.value;
    unawaited(_persistViewMode());
  }
}
