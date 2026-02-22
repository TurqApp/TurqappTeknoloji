import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StoryLikesController extends GetxController {
  RxList<String> list = <String>[].obs;
  var totalLike = 0.obs;
  Future<void> getData(String storyID) async {
    await FirebaseFirestore.instance
        .collection("Stories")
        .doc(storyID)
        .collection("likes")
        .get()
        .then((snap) {
      list.assignAll(snap.docs.map((val) => val.id).toList());
    });

    await FirebaseFirestore.instance
        .collection("Stories")
        .doc(storyID)
        .collection("likes")
        .count()
        .get()
        .then((counts) {
      totalLike.value = counts.count ?? 0;
    });
  }
}
