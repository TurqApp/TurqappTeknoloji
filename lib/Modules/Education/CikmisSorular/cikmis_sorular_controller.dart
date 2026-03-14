import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';

class CikmisSorularController extends GetxController {
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();

  final covers = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;

  Timer? _searchDebounce;
  int _searchToken = 0;

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      const baslikSirasi = <String>[
        'LGS',
        'YKS',
        'KPSS',
        'ALES',
        'YDS',
        'DGS',
        'TUS',
        'DUS',
      ];
      final items = await _repository.fetchCovers();
      items.sort((a, b) {
        var indexA = baslikSirasi.indexOf(a.anaBaslik);
        var indexB = baslikSirasi.indexOf(b.anaBaslik);
        if (indexA == -1) indexA = baslikSirasi.length;
        if (indexB == -1) indexB = baslikSirasi.length;
        return indexA.compareTo(indexB);
      });
      covers.assignAll(
        items
            .map(
              (item) => <String, dynamic>{
                '_docId': item.docID,
                'anaBaslik': item.anaBaslik,
                'sinavTuru': item.sinavTuru,
              },
            )
            .toList(growable: false),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      _searchToken++;
      isSearchLoading.value = false;
      searchResults.clear();
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.pastQuestion,
        query: normalized,
        limit: 40,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final docs = await _repository.fetchRootDocsByIds(docIds);
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      searchResults.assignAll(docs);
    } catch (e) {
      debugPrint('Past question typesense search error: $e');
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
