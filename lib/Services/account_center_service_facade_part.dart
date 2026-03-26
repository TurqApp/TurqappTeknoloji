part of 'account_center_service.dart';

AccountCenterService? maybeFindAccountCenterService() =>
    _maybeFindAccountCenterService();

AccountCenterService ensureAccountCenterService() =>
    _ensureAccountCenterService();

AccountCenterService? _maybeFindAccountCenterService() {
  final isRegistered = Get.isRegistered<AccountCenterService>();
  if (!isRegistered) return null;
  return Get.find<AccountCenterService>();
}

AccountCenterService _ensureAccountCenterService() {
  final existing = _maybeFindAccountCenterService();
  if (existing != null) return existing;
  return Get.put(AccountCenterService(), permanent: true);
}

void _handleAccountCenterServiceInit(AccountCenterService controller) {
  if (controller._initScheduled) return;
  controller._initScheduled = true;
  unawaited(controller.init());
}

extension AccountCenterServiceFacadePart on AccountCenterService {
  bool get _shouldLogDebug => kDebugMode && !IntegrationTestMode.enabled;

  int _compareAccounts(StoredAccount a, StoredAccount b) {
    final active = activeUid.value.trim();
    if (active.isNotEmpty) {
      final aIsActive = a.uid == active;
      final bIsActive = b.uid == active;
      if (aIsActive != bIsActive) {
        return aIsActive ? -1 : 1;
      }
    }
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    if (a.sortOrder != b.sortOrder) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    return b.lastUsedAt.compareTo(a.lastUsedAt);
  }
}
