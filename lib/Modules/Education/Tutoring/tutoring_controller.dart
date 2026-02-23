import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringController extends GetxController {
  final FocusNode focusNode = FocusNode();
  var isLoading = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<QuerySnapshot>? _tutoringSubscription;

  @override
  void onInit() {
    super.onInit();
    listenToTutoringData();
  }

  @override
  void dispose() {
    _tutoringSubscription?.cancel();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> fetchUserData(String userID) async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (studentDoc.exists) {
        users[userID] = studentDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      log("Error fetching user data: $e");
    }
  }

  void listenToTutoringData() {
    isLoading.value = true;
    _tutoringSubscription = FirebaseFirestore.instance
        .collection('OzelDersVerenler')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) async {
      try {
        List<TutoringModel> tempList = querySnapshot.docs
            .map(
              (doc) => TutoringModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        log("Fetched ${tempList.length} tutoring items");
        for (var tutoring in tempList) {
          if (!users.containsKey(tutoring.userID)) {
            await fetchUserData(tutoring.userID);
          }
        }

        tutoringList.value = tempList;
      } catch (e) {
        log("Error processing tutoring stream: $e");
        tutoringList.value = [];
      } finally {
        isLoading.value = false;
      }
    }, onError: (e) {
      log("Error listening to tutoring data: $e");
      isLoading.value = false;
    });
  }

  Future<void> toggleFavorite(
    String docId,
    String userId,
    bool isFavorite,
  ) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('OzelDersVerenler').doc(docId);
      final tutoringIndex = tutoringList.indexWhere((t) => t.docID == docId);
      if (tutoringIndex != -1) {
        final currentTutoring = tutoringList[tutoringIndex];
        final updatedFavorites = List<String>.from(currentTutoring.favorites);
        if (isFavorite) {
          updatedFavorites.remove(userId);
        } else if (!updatedFavorites.contains(userId)) {
          updatedFavorites.add(userId);
        }
        await docRef.update({'favorites': updatedFavorites});
        tutoringList[tutoringIndex] = currentTutoring.copyWith(
          favorites: updatedFavorites,
        );
        tutoringList.refresh();
      }
    } catch (e) {
      log("Error toggling favorite: $e");
    }
  }
}

extension TutoringModelExtension on TutoringModel {
  TutoringModel copyWith({
    String? docID,
    String? aciklama,
    String? baslik,
    String? brans,
    String? cinsiyet,
    List<String>? dersYeri,
    num? end,
    List<String>? favorites,
    num? fiyat,
    List<String>? imgs,
    String? ilce,
    bool? onayVerildi,
    String? sehir,
    bool? telefon,
    num? timeStamp,
    String? userID,
    bool? whatsapp,
  }) {
    return TutoringModel(
      docID: docID ?? this.docID,
      aciklama: aciklama ?? this.aciklama,
      baslik: baslik ?? this.baslik,
      brans: brans ?? this.brans,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      dersYeri: dersYeri ?? this.dersYeri,
      end: end ?? this.end,
      favorites: favorites ?? this.favorites,
      fiyat: fiyat ?? this.fiyat,
      imgs: imgs ?? this.imgs,
      ilce: ilce ?? this.ilce,
      onayVerildi: onayVerildi ?? this.onayVerildi,
      sehir: sehir ?? this.sehir,
      telefon: telefon ?? this.telefon,
      timeStamp: timeStamp ?? this.timeStamp,
      userID: userID ?? this.userID,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}
