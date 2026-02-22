import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/FollowService.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Models/PostsModel.dart';

class NotificationContentController extends GetxController {
  String userID;

  NotificationContentController({required this.userID});
  var pfImage = "".obs;
  var nickname = "".obs;
  var following = false.obs;
  var followLoading = false.obs;
  var model = PostsModel.empty().obs;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get()
        .then((doc) {
      pfImage.value = doc.get("pfImage");
      nickname.value = doc.get("nickname");
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("TakipEdilenler")
        .doc(userID)
        .get()
        .then((doc) {
      following.value = doc.exists;
    });
  }

  Future<void> getPostData(String docID) async {
    print("VERI CEKILDI");
    FirebaseFirestore.instance.collection("Posts").doc(docID).get().then((doc) {
      final data = doc.data();
      if (data == null) return;
      final m = PostsModel.fromMap(data, docID);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isVisibleNow = m.timeStamp <= nowMs;
      if (isVisibleNow && m.deletedPost != true) {
        model.value = m;
      } else {
        // Zamanı gelmemiş veya silinmiş gönderiyi göstermeyelim
        model.value = PostsModel.empty();
      }
    });
  }

  Future<void> toggleFollowStatus(String userID) async {
    if (followLoading.value) return;
    final wasFollowing = following.value;
    following.value = !wasFollowing; // optimistic
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      following.value = outcome.nowFollowing; // reconcile
      if (outcome.limitReached) {
        AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
      }
    } catch (e) {
      following.value = wasFollowing; // revert
    } finally {
      followLoading.value = false;
    }
  }
}
