part of 'notify_lookup_repository.dart';

class NotifyLookupRepository extends GetxService {
  NotifyLookupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _postLookupTtl = Duration(seconds: 30);
  static const Duration _chatLookupTtl = Duration(seconds: 30);
  static const Duration _jobLookupTtl = Duration(seconds: 30);
  static const Duration _tutoringLookupTtl = Duration(seconds: 30);
  static const Duration _marketLookupTtl = Duration(seconds: 30);
  static const Duration _staleRetention = Duration(minutes: 3);
  static const int _maxLookupEntries = 300;

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
