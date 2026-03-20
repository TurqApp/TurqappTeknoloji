import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class TutoringSearchController extends GetxController {
  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TextEditingController searchController = TextEditingController();
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;

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

  Future<void> _bootstrapInitialData() async {
    try {
      final resource = await _tutoringSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 60,
      );
      final cachedItems = resource.data ?? const <TutoringModel>[];
      if (cachedItems.isNotEmpty) {
        _initialTutorings = cachedItems;
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
      searchResults.value = items;
    } catch (_) {
      searchResults.value = const <TutoringModel>[];
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
