import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../Models/HashtagModel.dart';

class HashtagListerController extends GetxController {
  RxList<HashtagModel> hashtags = <HashtagModel>[].obs;

  
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseFirestore.instance.collection("HashTags")
    .orderBy("counter", descending: true)
    .limit(20)
    .get()
    .then((snap){
      for (var doc in snap.docs){
        hashtags.add(HashtagModel(hashtag: doc.id, count: doc.get("counter")));
      }
    });
  }
}