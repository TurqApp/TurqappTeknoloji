import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticsAndBooksPublishedController extends GetxController {
  final list = <BookletModel>[].obs;
  final optikler = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final RxDouble scrollOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> loadData() async {
    isLoading.value = true;
    await Future.wait([getData(), getOptikler()]);
    isLoading.value = false;
  }

  Future<void> getData() async {
    final snapshots = await FirebaseFirestore.instance
        .collection("Kitapciklar")
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final tempList = <BookletModel>[];
    for (var doc in snapshots.docs) {
      tempList.add(
        BookletModel(
          dil: doc.get("dil"),
          sinavTuru: doc.get("sinavTuru"),
          cover: doc.get("cover"),
          baslik: doc.get("baslik"),
          timeStamp: doc.get("timeStamp"),
          kaydet: List.from(doc.get("kaydet")),
          basimTarihi: doc.get("basimTarihi"),
          yayinEvi: doc.get("yayinEvi"),
          docID: doc.id,
          userID: doc.get("userID"),
          goruntuleme: List.from(doc.get("goruntuleme")),
        ),
      );
    }
    tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    list.assignAll(tempList);
  }

  Future<void> getOptikler() async {
    final snap = await FirebaseFirestore.instance
        .collection("OptikKodlar")
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final tempList = <OpticalFormModel>[];
    for (var doc in snap.docs) {
      tempList.add(
        OpticalFormModel(
          docID: doc.id,
          name: doc.get("name"),
          cevaplar: List.from(doc.get("cevaplar")),
          max: doc.get("max"),
          userID: doc.get("userID"),
          baslangic: doc.get("baslangic"),
          bitis: doc.get("bitis"),
          kisitlama: doc.get("kisitlama"),
        ),
      );
    }
    optikler.assignAll(tempList);
  }
}
