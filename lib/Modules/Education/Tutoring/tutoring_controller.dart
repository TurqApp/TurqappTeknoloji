import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'tutoring_controller_data_part.dart';
part 'tutoring_controller_model_extension_part.dart';
part 'tutoring_controller_search_part.dart';

class TutoringController extends GetxController {
  static TutoringController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringController(), permanent: permanent);
  }

  static TutoringController? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringController>();
    if (!isRegistered) return null;
    return Get.find<TutoringController>();
  }

  final TutoringSnapshotRepository _tutoringSnapshotRepository =
      TutoringSnapshotRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchPreviewController = TextEditingController();
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var searchResults = <TutoringModel>[].obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<CachedResource<List<TutoringModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;
  int _currentPage = 1;

  String _firstImage(TutoringModel item) {
    final imgs = item.imgs;
    if (imgs == null || imgs.isEmpty) return '';
    return imgs.first;
  }

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
            item.dersYeri.join('|'),
            _firstImage(item),
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
            item.dersYeri.join('|'),
            _firstImage(item),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  bool _sameTutoringList(List<TutoringModel> next) =>
      _sameTutoringEntries(tutoringList, next);

  static const int _pageSize = 30;
  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    unawaited(_bootstrapTutoringData());
  }

  Future<void> _bootstrapTutoringData() async {
    final savedController = SavedTutoringsController.ensure(permanent: true);
    await savedController.loadSavedTutorings();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _tutoringSnapshotRepository
        .openHome(
          userId: userId,
          limit: _pageSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    focusNode.dispose();
    searchPreviewController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
