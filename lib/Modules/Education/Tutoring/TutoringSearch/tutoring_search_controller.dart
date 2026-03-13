import 'dart:developer';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSearchController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
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
      final fetched = await _userRepository.getUsersRaw(toFetch);
      users.addAll(fetched);
    } catch (e) {
      log("Error batch fetching users: $e");
    }
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      final page = await _tutoringRepository.fetchPage(limit: 200);
      _allTutorings = page.items;

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
