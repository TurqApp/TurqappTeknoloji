import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSearchController extends GetxController {
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  /// Full list cached for client-side filtering
  List<TutoringModel> _allTutorings = [];

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        searchResults.value = _allTutorings;
      }
    }, time: Duration(milliseconds: 500));
  }

  Future<void> _batchFetchUsers(Set<String> userIds) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      for (var i = 0; i < toFetch.length; i += 30) {
        final batch = toFetch.skip(i).take(30).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (var doc in snap.docs) {
          users[doc.id] = doc.data();
        }
      }
    } catch (e) {
      log("Error batch fetching users: $e");
    }
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('educators')
          .orderBy('timeStamp', descending: true)
          .limit(200)
          .get();

      _allTutorings = querySnapshot.docs
          .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
          .toList();

      final userIds = _allTutorings.map((t) => t.userID).toSet();
      await _batchFetchUsers(userIds);

      searchResults.value = _allTutorings;
    } catch (e) {
      log("Error fetching initial data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void performSearch(String query) {
    final q = query.toLowerCase();
    searchResults.value = _allTutorings
        .where((tutoring) =>
            tutoring.aciklama.toLowerCase().contains(q) ||
            tutoring.baslik.toLowerCase().contains(q) ||
            tutoring.brans.toLowerCase().contains(q))
        .toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
