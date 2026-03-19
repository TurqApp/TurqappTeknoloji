import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSearchController extends GetxController {
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TextEditingController searchController = TextEditingController();
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;

  List<TutoringModel> _initialTutorings = [];

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapInitialData());
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
      final fetched = await _userSummaryResolver.resolveMany(toFetch);
      users.addAll(
        fetched.map((key, value) => MapEntry(key, value.toMap())),
      );
    } catch (_) {
    }
  }

  Future<void> _bootstrapInitialData() async {
    try {
      final resource = await _tutoringSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 60,
      );
      final cachedItems = resource.data ?? const <TutoringModel>[];
      if (cachedItems.isNotEmpty) {
        _initialTutorings = cachedItems;
        await _batchFetchUsers(cachedItems.map((t) => t.userID).toSet());
        searchResults.value = cachedItems;
        isLoading.value = false;
        await fetchInitialData(silent: true);
        return;
      }
    } catch (_) {}

    await fetchInitialData();
  }

  Future<void> fetchInitialData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final shouldShowLoader = !silent && searchResults.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 60,
        forceSync: forceRefresh,
      );
      _initialTutorings = result.data ?? const <TutoringModel>[];

      final userIds = _initialTutorings.map((t) => t.userID).toSet();
      await _batchFetchUsers(userIds);

      searchResults.value = _initialTutorings;
    } catch (_) {
    } finally {
      if (shouldShowLoader || searchResults.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  Future<void> performSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      searchResults.value = _initialTutorings;
      return;
    }

    try {
      final result = await _tutoringSnapshotRepository.search(
        query: normalized,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 60,
        forceSync: true,
      );
      final items = result.data ?? const <TutoringModel>[];
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
