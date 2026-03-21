import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  bool _sameIds(Iterable<String> next) {
    return listEquals(
      savedTutoringIds.toList(growable: false),
      next.toList(growable: false),
    );
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedTutorings();
  }

  Future<void> loadSavedTutorings() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    try {
      final entries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'educators',
        preferCache: true,
        forceRefresh: false,
      );
      final nextIds = entries.map((doc) => doc.id).toList(growable: false);
      if (!_sameIds(nextIds)) {
        savedTutoringIds.assignAll(nextIds);
      }
    } catch (_) {}
  }

  Future<void> addSavedTutoring(String docId) async {
    if (!savedTutoringIds.contains(docId)) {
      savedTutoringIds.add(docId);
      final uid = CurrentUserService.instance.userId;
      if (uid.isNotEmpty) {
        await _subcollectionRepository.setEntries(
          uid,
          subcollection: 'educators',
          items: savedTutoringIds
              .map(
                (id) => UserSubcollectionEntry(
                  id: id,
                  data: const <String, dynamic>{},
                ),
              )
              .toList(growable: false),
        );
      }
    }
  }

  Future<void> removeSavedTutoring(String docId) async {
    if (savedTutoringIds.contains(docId)) {
      savedTutoringIds.remove(docId);
      final uid = CurrentUserService.instance.userId;
      if (uid.isNotEmpty) {
        await _subcollectionRepository.setEntries(
          uid,
          subcollection: 'educators',
          items: savedTutoringIds
              .map(
                (id) => UserSubcollectionEntry(
                  id: id,
                  data: const <String, dynamic>{},
                ),
              )
              .toList(growable: false),
        );
      }
    }
  }
}
