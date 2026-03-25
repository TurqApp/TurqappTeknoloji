import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_tutorings_controller_runtime_part.dart';

class SavedTutoringsController extends GetxController {
  static SavedTutoringsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedTutoringsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedTutoringsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedTutoringsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedTutoringsController>(tag: tag);
  }

  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  var savedTutoringIds = <String>[].obs;

  bool _sameIds(Iterable<String> next) => _sameSavedTutoringIds(this, next);

  @override
  void onInit() {
    super.onInit();
    _handleSavedTutoringsInit(this);
  }

  Future<void> loadSavedTutorings() => _loadSavedTutorings(this);

  Future<void> addSavedTutoring(String docId) => _addSavedTutoring(this, docId);

  Future<void> removeSavedTutoring(String docId) =>
      _removeSavedTutoring(this, docId);
}
