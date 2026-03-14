import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class SavedOpticalFormsController extends GetxController {
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.clear();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final savedEntries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: "books",
        orderByField: "createdAt",
        descending: true,
        preferCache: true,
      );
      final books = await _bookletRepository.fetchByIds(
        savedEntries.map((e) => e.id).toList(growable: false),
        preferCache: true,
      );
      list.assignAll(books);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
