import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';

class MyTutoringApplicationsController extends GetxController {
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  RxList<TutoringApplicationModel> applications =
      <TutoringApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myTutoringApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: true,
        forceRefresh: false,
      );

      applications.value = items
          .map((doc) => TutoringApplicationModel.fromMap(doc.data, doc.id))
          .toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String tutoringDocID) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _tutoringRepository.cancelApplication(
        tutoringId: tutoringDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.tutoringDocID == tutoringDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myTutoringApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.tutoringDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
    }
  }
}
