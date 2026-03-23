import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class CikmisSorularController extends GetxController {
  static CikmisSorularController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularController(), permanent: permanent);
  }

  static CikmisSorularController? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularController>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularController>();
  }

  final CikmisSorularSnapshotRepository _snapshotRepository =
      CikmisSorularSnapshotRepository.ensure();
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();

  final covers = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;

  Timer? _searchDebounce;
  int _searchToken = 0;
  StreamSubscription<CachedResource<List<Map<String, dynamic>>>>?
      _homeSnapshotSub;

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapInitialData());
  }

  Future<void> _bootstrapInitialData() async {
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _snapshotRepository
        .openHome(userId: userId)
        .listen(_applyHomeSnapshotResource);
  }

  Future<void> refreshData({bool silent = false}) async {
    final shouldShowLoader = !silent && covers.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      final resource = await _snapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        forceSync: !silent,
      );
      final items = resource.data ?? const <Map<String, dynamic>>[];
      _assignCoverDocs(items);
    } finally {
      if (shouldShowLoader || covers.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  void _assignCoverDocs(List<Map<String, dynamic>> rawDocs) {
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
    final items = rawDocs
        .map(
          (doc) => CikmisSorularCoverModel(
            anaBaslik: (doc['anaBaslik'] ?? '').toString(),
            docID: (doc['_docId'] ?? '').toString(),
            sinavTuru: (doc['sinavTuru'] ?? '').toString(),
          ),
        )
        .where((item) => item.anaBaslik.isNotEmpty)
        .toList(growable: true);
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
      final docs = await _repository.fetchRootDocs(
        preferCache: true,
        forceRefresh: true,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      final lowered = normalized.toLowerCase();
      final filtered = docs.where((doc) {
        final haystack = <String>[
          (doc['title'] ?? '').toString(),
          (doc['subtitle'] ?? '').toString(),
          (doc['description'] ?? '').toString(),
          (doc['anaBaslik'] ?? '').toString(),
          (doc['sinavTuru'] ?? '').toString(),
          (doc['yil'] ?? '').toString(),
          (doc['baslik2'] ?? '').toString(),
          (doc['baslik3'] ?? '').toString(),
          (doc['dil'] ?? '').toString(),
        ].join(' ').toLowerCase();
        return haystack.contains(lowered);
      }).toList(growable: false);
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      searchResults.assignAll(filtered);
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
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    super.onClose();
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<Map<String, dynamic>>> resource,
  ) {
    final docs = resource.data ?? const <Map<String, dynamic>>[];
    if (docs.isNotEmpty) {
      _assignCoverDocs(docs);
    }

    if (!resource.isRefreshing || docs.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (covers.isEmpty) {
      isLoading.value = true;
    }
  }
}
