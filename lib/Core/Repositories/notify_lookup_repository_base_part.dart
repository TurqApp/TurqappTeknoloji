part of 'notify_lookup_repository.dart';

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
