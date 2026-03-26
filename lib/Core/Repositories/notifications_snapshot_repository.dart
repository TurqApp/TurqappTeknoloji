import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Models/notification_model.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';

part 'notifications_snapshot_repository_query_part.dart';
part 'notifications_snapshot_repository_action_part.dart';
part 'notifications_snapshot_repository_fields_part.dart';

class NotificationsSnapshotQuery {
  const NotificationsSnapshotQuery({
    required this.userId,
    this.limit = ReadBudgetRegistry.notificationsInboxInitialLimit,
    this.scopeTag = 'inbox',
  });

  final String userId;
  final int limit;
  final String scopeTag;

  String get scopeId => <String>[
        'limit=$limit',
        'scope=${scopeTag.trim()}',
      ].join('|');
}

class NotificationsSnapshotRepository extends GetxService {
  NotificationsSnapshotRepository();

  static const String _surfaceKey = 'notifications_inbox_snapshot';

  static NotificationsSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotificationsSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<NotificationsSnapshotRepository>();
  }

  static NotificationsSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotificationsSnapshotRepository(), permanent: true);
  }

  late final _NotificationsSnapshotRepositoryState _state =
      _NotificationsSnapshotRepositoryState(this);
}
