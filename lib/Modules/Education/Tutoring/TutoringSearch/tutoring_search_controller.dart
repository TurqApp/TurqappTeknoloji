import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TutoringSearchController extends GetxController {
  static TutoringSearchController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringSearchController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringSearchController? maybeFind({String? tag}) {
    if (!Get.isRegistered<TutoringSearchController>(tag: tag)) return null;
    return Get.find<TutoringSearchController>(tag: tag);
  }

  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TextEditingController searchController = TextEditingController();
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var searchResults = <TutoringModel>[].obs;

  List<TutoringModel> _initialTutorings = [];

  bool _sameTutoringEntries(
    List<TutoringModel> current,
    List<TutoringModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapInitialData());
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        performSearch(query);
      } else {
        if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
          searchResults.value = _initialTutorings;
        }
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
        userId: CurrentUserService.instance.userId,
        limit: 60,
      );
      final cachedItems = resource.data ?? const <TutoringModel>[];
      if (cachedItems.isNotEmpty) {
        _initialTutorings = cachedItems;
        if (!_sameTutoringEntries(searchResults, cachedItems)) {
          searchResults.value = cachedItems;
        }
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
        userId: CurrentUserService.instance.userId,
        limit: 60,
        forceSync: forceRefresh,
      );
      _initialTutorings = result.data ?? const <TutoringModel>[];
      if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
        searchResults.value = _initialTutorings;
      }
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
      if (!_sameTutoringEntries(searchResults, _initialTutorings)) {
        searchResults.value = _initialTutorings;
      }
      return;
    }

    try {
      final result = await _tutoringSnapshotRepository.search(
        query: normalized,
        userId: CurrentUserService.instance.userId,
        limit: 60,
        forceSync: true,
      );
      final items = result.data ?? const <TutoringModel>[];
      if (!_sameTutoringEntries(searchResults, items)) {
        searchResults.value = items;
      }
    } catch (_) {
      if (searchResults.isNotEmpty) {
        searchResults.value = const <TutoringModel>[];
      }
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
