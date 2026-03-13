import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticsAndBooksPublishedController extends GetxController {
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  final list = <BookletModel>[].obs;
  final optikler = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;
  int _lastOpenRefreshAt = 0;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setSelection(int value) {
    selection.value = value;
  }

  void refreshOnOpen() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (isLoading.value) return;
    if (now - _lastOpenRefreshAt < 800) return;
    _lastOpenRefreshAt = now;
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    await Future.wait([getData(), getOptikler()]);
    isLoading.value = false;
  }

  Future<void> getData() async {
    final tempList = await _bookletRepository.fetchByOwner(
      FirebaseAuth.instance.currentUser!.uid,
      preferCache: true,
    );
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    list.assignAll(tempList);
  }

  Future<void> getOptikler() async {
    final tempList = await _opticalFormRepository.fetchByOwner(
      FirebaseAuth.instance.currentUser!.uid,
      preferCache: true,
    );
    tempList.sort((a, b) => b.docID.compareTo(a.docID));
    optikler.assignAll(tempList);
  }
}
