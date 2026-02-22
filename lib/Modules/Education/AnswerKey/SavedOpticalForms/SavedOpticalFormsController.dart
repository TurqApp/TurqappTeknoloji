import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/BookletModel.dart';

class SavedOpticalFormsController extends GetxController {
  final list = <BookletModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    isLoading.value = true;
    try {
      list.clear();
      final snapshots =
          await FirebaseFirestore.instance
              .collection("Kitapciklar")
              .orderBy("timeStamp", descending: true)
              .get();

      for (var doc in snapshots.docs) {
        final basimTarihi = doc.get("basimTarihi") as String;
        final baslik = doc.get("baslik") as String;
        final cover = doc.get("cover") as String;
        final dil = doc.get("dil") as String;
        final kaydet = List<String>.from(doc.get("kaydet"));
        final goruntuleme = List<String>.from(doc.get("goruntuleme"));
        final sinavTuru = doc.get("sinavTuru") as String;
        final timeStamp = doc.get("timeStamp") as num;
        final yayinEvi = doc.get("yayinEvi") as String;
        final userID = doc.get("userID") as String;

        if (kaydet.contains(FirebaseAuth.instance.currentUser!.uid)) {
          list.add(
            BookletModel(
              dil: dil,
              sinavTuru: sinavTuru,
              cover: cover,
              baslik: baslik,
              timeStamp: timeStamp,
              kaydet: kaydet,
              basimTarihi: basimTarihi,
              yayinEvi: yayinEvi,
              docID: doc.id,
              userID: userID,
              goruntuleme: goruntuleme,
            ),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
