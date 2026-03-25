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

  List<String> lessons = [
    "LGS",
    "TYT",
    "AYT",
    "YDT",
    "YDS",
    "ALES",
    "DGS",
    "KPSS",
    "DUS",
    "TUS",
    "Dil",
    "Yazılım",
    "Spor",
    "Tasarım",
  ];

  final List<Color> colors = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.cyan.shade700,
    Colors.blueGrey,
    Colors.pink.shade900,
  ];

  List<Color> lessonsColors = [
    Colors.lightBlue.shade700,
    Colors.pink.shade600,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.red.shade800,
    Colors.indigo.shade800,
    Colors.lime.shade700,
    Colors.brown.shade800,
    Colors.blue.shade800,
    Colors.cyan.shade800,
    Colors.purple.shade700,
    Colors.teal.shade700,
    Colors.red.shade700,
    Colors.deepOrange.shade700,
  ];

  List<IconData> lessonsIcons = [
    Icons.psychology,
    Icons.school,
    Icons.library_books,
    Icons.translate,
    Icons.language,
    Icons.book_online,
    Icons.calculate,
    Icons.assignment,
    Icons.health_and_safety,
    Icons.medical_services,
    Icons.translate,
    Icons.code,
    Icons.sports_basketball,
    Icons.design_services,
  ];

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
