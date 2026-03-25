import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Agenda/AgendaContent/agenda_content_controller.dart';

part 'archives_controller_lifecycle_part.dart';
part 'archives_controller_data_part.dart';
part 'archives_controller_support_part.dart';

class ArchiveController extends GetxController {
  static ArchiveController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ArchiveController());
  }

  static ArchiveController? maybeFind() {
    final isRegistered = Get.isRegistered<ArchiveController>();
    if (!isRegistered) return null;
    return Get.find<ArchiveController>();
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final scrollController = ScrollController();

  final RxList<PostsModel> list = <PostsModel>[].obs;
  final RxBool isLoading = true.obs;
  final Map<String, GlobalKey> _agendaKeys = {};
  final currentVisibleIndex = RxInt(-1);
  int? lastCenteredIndex;
  final centeredIndex = 0.obs;
  String? _pendingCenteredDocId;
  StreamSubscription<User?>? _authSub;
  String? _currentUserId;

  String get _resolvedCurrentUid => CurrentUserService.instance.effectiveUserId;

  Future<void> fetchData({bool silent = false}) async {
    await _ArchiveControllerDataPart(this).fetchArchiveData(silent: silent);
  }

  @override
  void onInit() {
    super.onInit();
    _ArchiveControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _ArchiveControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
