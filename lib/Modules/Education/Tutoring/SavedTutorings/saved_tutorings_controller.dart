import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

class SavedTutoringsController extends GetxController {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
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
