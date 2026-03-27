part of 'saved_tutorings_controller.dart';

class SavedTutoringsController extends GetxController {
  final _subcollectionRepository = ensureUserSubcollectionRepository();
  var savedTutoringIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _handleSavedTutoringsInit(this);
  }
}

bool _sameSavedTutoringIds(
  SavedTutoringsController controller,
  Iterable<String> next,
) {
  return listEquals(
    controller.savedTutoringIds.toList(growable: false),
    next.toList(growable: false),
  );
}

void _handleSavedTutoringsInit(SavedTutoringsController controller) {
  _loadSavedTutorings(controller);
}

Future<void> _loadSavedTutorings(SavedTutoringsController controller) async {
  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty) return;
  try {
    final entries = await controller._subcollectionRepository.getEntries(
      uid,
      subcollection: 'educators',
      preferCache: true,
      forceRefresh: false,
    );
    final nextIds = entries.map((doc) => doc.id).toList(growable: false);
    if (!_sameSavedTutoringIds(controller, nextIds)) {
      controller.savedTutoringIds.assignAll(nextIds);
    }
  } catch (_) {}
}

Future<void> _addSavedTutoring(
  SavedTutoringsController controller,
  String docId,
) async {
  if (!controller.savedTutoringIds.contains(docId)) {
    controller.savedTutoringIds.add(docId);
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isNotEmpty) {
      await controller._subcollectionRepository.setEntries(
        uid,
        subcollection: 'educators',
        items: controller.savedTutoringIds
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

Future<void> _removeSavedTutoring(
  SavedTutoringsController controller,
  String docId,
) async {
  if (controller.savedTutoringIds.contains(docId)) {
    controller.savedTutoringIds.remove(docId);
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isNotEmpty) {
      await controller._subcollectionRepository.setEntries(
        uid,
        subcollection: 'educators',
        items: controller.savedTutoringIds
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
