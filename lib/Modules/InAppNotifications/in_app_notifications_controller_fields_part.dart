part of 'in_app_notifications_controller.dart';

class _InAppNotificationsControllerState {
  final selection = 0.obs;
  final pageController = PageController(initialPage: 0);
  final list = <NotificationModel>[].obs;
  final complatedDataFetch = false.obs;
  final busyMarkAllRead = false.obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? notificationSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      newNotificationHeadSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? settingsSub;
  final allNotifications = <NotificationModel>[];
  Map<String, dynamic> preferences = NotificationPreferencesService.defaults();
  final unreadTotal = 0.obs;
  final notificationsRepository = NotificationsRepository.ensure();
  final notificationsSnapshotRepository =
      ensureNotificationsSnapshotRepository();
  bool markAllReadQueued = false;
  bool inboxSeenRequested = false;
}

extension InAppNotificationsControllerFieldsPart
    on InAppNotificationsController {
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
  RxList<NotificationModel> get list => _state.list;
  RxBool get complatedDataFetch => _state.complatedDataFetch;
  RxBool get busyMarkAllRead => _state.busyMarkAllRead;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      get _notificationSub => _state.notificationSub;
  set _notificationSub(
          StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? value) =>
      _state.notificationSub = value;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      get _newNotificationHeadSub => _state.newNotificationHeadSub;
  set _newNotificationHeadSub(
          StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? value) =>
      _state.newNotificationHeadSub = value;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      get _settingsSub => _state.settingsSub;
  set _settingsSub(
          StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? value) =>
      _state.settingsSub = value;
  List<NotificationModel> get _allNotifications => _state.allNotifications;
  Map<String, dynamic> get _preferences => _state.preferences;
  set _preferences(Map<String, dynamic> value) => _state.preferences = value;
  RxInt get unreadTotal => _state.unreadTotal;
  NotificationsRepository get _notificationsRepository =>
      _state.notificationsRepository;
  NotificationsSnapshotRepository get _notificationsSnapshotRepository =>
      _state.notificationsSnapshotRepository;
  bool get _markAllReadQueued => _state.markAllReadQueued;
  set _markAllReadQueued(bool value) => _state.markAllReadQueued = value;
  bool get _inboxSeenRequested => _state.inboxSeenRequested;
  set _inboxSeenRequested(bool value) => _state.inboxSeenRequested = value;
  String get _currentUid => CurrentUserService.instance.effectiveUserId;
}
