import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/answer_key_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/AnswerKeyContent/answer_key_content_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'answer_key_controller_data_part.dart';
part 'answer_key_controller_search_part.dart';
part 'answer_key_controller_ui_part.dart';

class AnswerKeyController extends GetxController {
  static AnswerKeyController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeyController(), permanent: permanent);
  }

  static AnswerKeyController? maybeFind() {
    final isRegistered = Get.isRegistered<AnswerKeyController>();
    if (!isRegistered) return null;
    return Get.find<AnswerKeyController>();
  }

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_answer_key_listing_selection';
  final AnswerKeySnapshotRepository _answerKeySnapshotRepository =
      AnswerKeySnapshotRepository.ensure();
  final BookletRepository _bookletRepository = BookletRepository.ensure();
  var isLoading = false.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final RxInt listingSelection = 1.obs;
  final RxBool listingSelectionReady = false.obs;
  var bookList = <BookletModel>[].obs;
  var searchResults = <BookletModel>[].obs;
  final RxString searchQuery = ''.obs;
  ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 30;
  StreamSubscription<CachedResource<List<BookletModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  void toggleListingSelection() {
    _toggleListingSelectionValue();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
