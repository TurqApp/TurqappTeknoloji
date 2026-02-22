import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/TutoringModel.dart';

class TutoringSearchController extends GetxController {
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        fetchInitialData();
      }
    }, time: Duration(milliseconds: 500));
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('OzelDersVerenler')
              .orderBy('timeStamp', descending: true)
              .get();
      List<TutoringModel> tempList =
          querySnapshot.docs
              .map(
                (doc) => TutoringModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      for (var tutoring in tempList) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(tutoring.userID)
                .get();
        if (userDoc.exists) {
          users[tutoring.userID] = userDoc.data() as Map<String, dynamic>;
        }
      }
      searchResults.value = tempList;
    } catch (e) {
      log("Error fetching initial data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> performSearch(String query) async {
    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('OzelDersVerenler').get();
      List<TutoringModel> tempList =
          querySnapshot.docs
              .map(
                (doc) => TutoringModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      for (var tutoring in tempList) {
        if (tutoring.aciklama.toLowerCase().contains(query.toLowerCase()) ||
            tutoring.baslik.toLowerCase().contains(query.toLowerCase()) ||
            tutoring.brans.toLowerCase().contains(query.toLowerCase())) {
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(tutoring.userID)
                  .get();
          if (userDoc.exists) {
            users[tutoring.userID] = userDoc.data() as Map<String, dynamic>;
          }
        }
      }
      searchResults.value =
          tempList
              .where(
                (tutoring) =>
                    tutoring.aciklama.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    tutoring.baslik.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    tutoring.brans.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    } catch (e) {
      log("Error searching tutoring data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
