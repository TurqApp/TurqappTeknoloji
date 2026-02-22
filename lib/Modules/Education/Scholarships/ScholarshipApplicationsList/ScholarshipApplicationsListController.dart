import 'package:get/get.dart';

class ScholarshipApplicationsListController extends GetxController {
  final String docID;
  final List<String> basvuranlar;

  ScholarshipApplicationsListController({
    required this.docID,
    required this.basvuranlar,
  });

  var isRefreshing = false.obs;

  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isRefreshing.value = false;
  }
}
