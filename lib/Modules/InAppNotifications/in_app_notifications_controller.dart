import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'in_app_notifications_controller_data_part.dart';
part 'in_app_notifications_controller_actions_part.dart';

class InAppNotificationsController extends GetxController {
  static InAppNotificationsController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(InAppNotificationsController(), tag: tag);
  }

  static InAppNotificationsController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<InAppNotificationsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<InAppNotificationsController>(tag: tag);
  }

  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);
  RxList<NotificationModel> list = <NotificationModel>[].obs;
  var complatedDataFetch = false.obs;
  var busyMarkAllRead = false.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _newNotificationHeadSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  final List<NotificationModel> _allNotifications = <NotificationModel>[];
  Map<String, dynamic> _preferences = NotificationPreferencesService.defaults();
  final RxInt unreadTotal = 0.obs;
  final NotificationsRepository _notificationsRepository =
      NotificationsRepository.ensure();
  final NotificationsSnapshotRepository _notificationsSnapshotRepository =
      NotificationsSnapshotRepository.ensure();
  bool _markAllReadQueued = false;
  bool _inboxSeenRequested = false;
  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void onInit() {
    super.onInit();
    _bindPreferences();
    getData();
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int get unreadCount => unreadTotal.value;

  @override
  void onClose() {
    _notificationSub?.cancel();
    _newNotificationHeadSub?.cancel();
    _settingsSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
