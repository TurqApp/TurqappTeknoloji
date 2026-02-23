import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StorySeensController extends GetxController {
  RxList<String> list = <String>[].obs;
  var totalSeen = 0.obs;

  Future<void> getData(String storyID) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("stories")
          .doc(storyID)
          .collection("Viewers")
          .limit(50)
          .get();
      list.assignAll(snap.docs.map((val) => val.id).toList());
    } catch (e) {
      print("Görüntüleme listesi alınamadı: $e");
      list.clear();
    }

    try {
      final counts = await FirebaseFirestore.instance
          .collection("stories")
          .doc(storyID)
          .collection("Viewers")
          .count()
          .get();
      totalSeen.value = counts.count ?? 0;
    } catch (e) {
      print("Toplam görülme alınamadı: $e");
      totalSeen.value = 0;
    }
  }
}
