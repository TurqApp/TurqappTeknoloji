part of 'deneme_sinavlari_controller.dart';

DenemeSinavlariController _ensureDenemeSinavlariController({
  bool permanent = false,
}) {
  final existing = _maybeFindDenemeSinavlariController();
  if (existing != null) return existing;
  return Get.put(DenemeSinavlariController(), permanent: permanent);
}

DenemeSinavlariController? _maybeFindDenemeSinavlariController() {
  final isRegistered = Get.isRegistered<DenemeSinavlariController>();
  if (!isRegistered) return null;
  return Get.find<DenemeSinavlariController>();
}

bool _hasActivePracticeExamSearch(DenemeSinavlariController controller) =>
    controller.searchQuery.value.trim().length >= 2;

void _handleDenemeSinavlariInit(DenemeSinavlariController controller) {
  controller._handlePracticeExamInit();
}

void _handleDenemeSinavlariClose(DenemeSinavlariController controller) {
  controller._handlePracticeExamClose();
}
