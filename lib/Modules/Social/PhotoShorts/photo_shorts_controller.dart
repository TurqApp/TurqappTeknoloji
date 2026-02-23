import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';

class PhotoShortsController extends GetxController {
  var list = <PostsModel>[].obs;

  Future<void> addToList(List<PostsModel> photoList) async {
    list.assignAll(photoList);
  }

  Future<void> updatePost(String docID) async {
    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(docID).get();
    if (doc.exists) {
      final updatedPost = PostsModel.fromMap(doc.data()!, doc.id);
      final idx = list.indexWhere((e) => e.docID == docID);
      if (idx != -1) {
        list[idx] = updatedPost;
        list.refresh();
      }
    }
  }
}
