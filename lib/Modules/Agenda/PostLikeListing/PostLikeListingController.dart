import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostLikeListingController extends GetxController {
  String postID;
  RxList<String> list = <String>[].obs;

  PostLikeListingController({
    required this.postID
});

  @override
  void onInit() {
    super.onInit();
    getLikes();
  }

  Future<void> getLikes() async {
    FirebaseFirestore.instance.collection("Posts").doc(postID).collection("likes").orderBy("timeStamp", descending: true).get()
        .then((snap){
          list.value = snap.docs.map((v) => v.id).toList();
    });
  }
}