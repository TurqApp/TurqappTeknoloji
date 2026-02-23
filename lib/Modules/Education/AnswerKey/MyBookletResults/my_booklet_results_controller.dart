import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class MyBookletResultsController extends GetxController {
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookletResults();
    fetchOptikSonuclari();
  }

  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> fetchBookletResults() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("KitapcikCevaplari")
        .orderBy("timeStamp", descending: true)
        .get();

    final tempList = <BookletResultModel>[];
    for (var doc in snapshot.docs) {
      tempList.add(
        BookletResultModel(
          cevaplar: List.from(doc.get("cevaplar")),
          docID: doc.id,
          baslik: doc.get("baslik"),
          timeStamp: doc.get("timeStamp"),
          yanlis: doc.get("yanlis"),
          dogru: doc.get("dogru"),
          bos: doc.get("bos"),
          kitapcikID: doc.get("kitapcikID"),
          puan: doc.get("puan"),
          dogruCevaplar: List.from(doc.get("dogruCevaplar")),
        ),
      );
    }
    list.assignAll(tempList);
  }

  Future<void> fetchOptikSonuclari() async {
    optikSonuclari.clear();
    final currentUserUID = FirebaseAuth.instance.currentUser!.uid;

    try {
      final optikSnapshot = await FirebaseFirestore.instance
          .collection("OptikKodlar")
          .orderBy("baslangic", descending: true)
          .get();

      for (var doc in optikSnapshot.docs) {
        final yanitlarSnapshot = await FirebaseFirestore.instance
            .collection("OptikKodlar")
            .doc(doc.id)
            .collection("Yanitlar")
            .doc(currentUserUID)
            .get();

        if (yanitlarSnapshot.exists) {
          print(
            "Found matching Yanitlar for User ID: $currentUserUID in OptikKodlar: ${doc.get('name')}",
          );
          optikSonuclari.add(
            OpticalFormModel(
              docID: doc.id,
              cevaplar: List<String>.from(doc.get('cevaplar') ?? []),
              max: doc.get("max"),
              name: doc.get("name"),
              userID: doc.get("userID"),
              bitis: doc.get("bitis"),
              baslangic: doc.get("baslangic"),
              kisitlama: doc.get("kisitlama"),
            ),
          );
        }
      }
    } catch (error) {
      print("Error fetching OptikKodlar data: $error");
    }
  }
}
