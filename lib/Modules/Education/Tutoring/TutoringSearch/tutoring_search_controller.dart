import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSearchController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final TextEditingController searchController = TextEditingController();
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  List<TutoringModel> _initialTutorings = [];

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        searchResults.value = _initialTutorings;
      }
    }, time: Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _batchFetchUsers(Set<String> userIds) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final fetched = await _userRepository.getUsersRaw(toFetch);
      users.addAll(fetched);
    } catch (_) {
    }
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.tutoring,
        query: '*',
        limit: 60,
        page: 1,
      );
      _initialTutorings = result.hits
          .map(TutoringModel.fromTypesenseHit)
          .where((item) => item.docID.isNotEmpty)
          .toList(growable: false);

      final userIds = _initialTutorings.map((t) => t.userID).toSet();
      await _batchFetchUsers(userIds);

      searchResults.value = _initialTutorings;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> performSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      searchResults.value = _initialTutorings;
      return;
    }

    try {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.tutoring,
        query: normalized,
        limit: 60,
        page: 1,
      );
      final items = result.hits
          .map(TutoringModel.fromTypesenseHit)
          .where((item) => item.docID.isNotEmpty)
          .toList(growable: false);
      await _batchFetchUsers(items.map((t) => t.userID).toSet());
      searchResults.value = items;
    } catch (_) {
      searchResults.value = const <TutoringModel>[];
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
