part of 'notify_lookup_repository_library.dart';

const Duration _notifyPostLookupTtl = Duration(seconds: 30);
const Duration _notifyChatLookupTtl = Duration(seconds: 30);
const Duration _notifyJobLookupTtl = Duration(seconds: 30);
const Duration _notifyTutoringLookupTtl = Duration(seconds: 30);
const Duration _notifyMarketLookupTtl = Duration(seconds: 30);
const Duration _notifyLookupStaleRetention = Duration(minutes: 3);
const int _notifyMaxLookupEntries = 300;

abstract class _NotifyLookupRepositoryBase extends GetxService {
  _NotifyLookupRepositoryBase({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, NotifyPostLookup> _postLookupCache =
      <String, NotifyPostLookup>{};
  final Map<String, NotifyChatLookup> _chatLookupCache =
      <String, NotifyChatLookup>{};
  final Map<String, NotifyJobLookup> _jobLookupCache =
      <String, NotifyJobLookup>{};
  final Map<String, NotifyTutoringLookup> _tutoringLookupCache =
      <String, NotifyTutoringLookup>{};
  final Map<String, NotifyMarketLookup> _marketLookupCache =
      <String, NotifyMarketLookup>{};
}

class NotifyLookupRepository extends _NotifyLookupRepositoryBase {
  NotifyLookupRepository({super.firestore});
}

NotifyLookupRepository? maybeFindNotifyLookupRepository() =>
    Get.isRegistered<NotifyLookupRepository>()
        ? Get.find<NotifyLookupRepository>()
        : null;

NotifyLookupRepository ensureNotifyLookupRepository() =>
    maybeFindNotifyLookupRepository() ??
    Get.put(NotifyLookupRepository(), permanent: true);
