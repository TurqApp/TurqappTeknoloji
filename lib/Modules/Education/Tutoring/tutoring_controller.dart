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
part 'tutoring_controller_runtime_part.dart';
part 'tutoring_controller_search_part.dart';
part 'tutoring_controller_support_part.dart';

class TutoringController extends GetxController {
  static TutoringController ensure({bool permanent = false}) =>
      _ensureTutoringController(permanent: permanent);

  static TutoringController? maybeFind() => _maybeFindTutoringController();

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

  static const int _pageSize = 30;
  bool get hasActiveSearch => _hasActiveTutoringSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleTutoringControllerInit(this);
  }

  @override
  void onClose() {
    _handleTutoringControllerClose(this);
    super.onClose();
  }
}
