import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'cikmis_sorular_controller_runtime_part.dart';

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
    unawaited(_handleOnInit());
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
