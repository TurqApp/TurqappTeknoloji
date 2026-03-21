import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class NotifyPostLookup {
  const NotifyPostLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final PostsModel? model;
  final DateTime cachedAt;
}

class NotifyChatLookup {
  const NotifyChatLookup({
    required this.otherUser,
    required this.cachedAt,
  });

  final String otherUser;
  final DateTime cachedAt;
}

class NotifyJobLookup {
  const NotifyJobLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final JobModel? model;
  final DateTime cachedAt;
}

class NotifyTutoringLookup {
  const NotifyTutoringLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final TutoringModel? model;
  final DateTime cachedAt;
}

class NotifyMarketLookup {
  const NotifyMarketLookup({
    required this.exists,
    required this.model,
    required this.cachedAt,
  });

  final bool exists;
  final MarketItemModel? model;
  final DateTime cachedAt;
}

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

  static NotifyLookupRepository ensure() {
    if (Get.isRegistered<NotifyLookupRepository>()) {
      return Get.find<NotifyLookupRepository>();
    }
    return Get.put(NotifyLookupRepository(), permanent: true);
  }

  Future<NotifyPostLookup> getPostLookup(String postID) async {
    _pruneStaleLookups();
    final cached = _postLookupCache[postID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _postLookupTtl) {
      return cached;
    }

    final doc = await _firestore.collection('Posts').doc(postID).get();
    final lookup = NotifyPostLookup(
      exists: doc.exists,
      model: doc.exists ? PostsModel.fromFirestore(doc) : null,
      cachedAt: DateTime.now(),
    );
    _postLookupCache[postID] = lookup;
    return lookup;
  }

  Future<NotifyChatLookup> getChatLookup(String chatID) async {
    _pruneStaleLookups();
    final currentUid = CurrentUserService.instance.userId;
    final cacheKey = '${currentUid}_$chatID';
    final cached = _chatLookupCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _chatLookupTtl) {
      return cached;
    }
    if (currentUid.isEmpty) {
      return NotifyChatLookup(otherUser: '', cachedAt: DateTime.now());
    }

    String otherUser = '';
    try {
      final convDoc =
          await _firestore.collection('conversations').doc(chatID).get();
      if (convDoc.exists) {
        final participants =
            List<String>.from(convDoc.data()?['participants'] ?? const []);
        otherUser = participants.firstWhere(
          (id) => id != currentUid,
          orElse: () => '',
        );
      }
    } catch (_) {}

    if (otherUser.isEmpty) {
      for (final part in chatID.split('_')) {
        final candidate = part.trim();
        if (candidate.isNotEmpty && candidate != currentUid) {
          otherUser = candidate;
          break;
        }
      }
    }

    final lookup = NotifyChatLookup(
      otherUser: otherUser,
      cachedAt: DateTime.now(),
    );
    _chatLookupCache[cacheKey] = lookup;
    return lookup;
  }

  Future<NotifyJobLookup> getJobLookup(String jobID) async {
    _pruneStaleLookups();
    final cached = _jobLookupCache[jobID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _jobLookupTtl) {
      return cached;
    }
    final doc = await _firestore.collection('isBul').doc(jobID).get();
    final lookup = NotifyJobLookup(
      exists: doc.exists,
      model: doc.exists ? JobModel.fromMap(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _jobLookupCache[jobID] = lookup;
    return lookup;
  }

  Future<NotifyTutoringLookup> getTutoringLookup(String tutoringID) async {
    _pruneStaleLookups();
    final cached = _tutoringLookupCache[tutoringID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _tutoringLookupTtl) {
      return cached;
    }
    final doc = await _firestore.collection('educators').doc(tutoringID).get();
    final lookup = NotifyTutoringLookup(
      exists: doc.exists,
      model: doc.exists ? TutoringModel.fromJson(doc.data()!, doc.id) : null,
      cachedAt: DateTime.now(),
    );
    _tutoringLookupCache[tutoringID] = lookup;
    return lookup;
  }

  Future<NotifyMarketLookup> getMarketLookup(String itemId) async {
    _pruneStaleLookups();
    final cached = _marketLookupCache[itemId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _marketLookupTtl) {
      return cached;
    }
    final model = await MarketRepository.ensure().fetchById(
      itemId,
      preferCache: true,
      forceRefresh: false,
    );
    final lookup = NotifyMarketLookup(
      exists: model != null,
      model: model,
      cachedAt: DateTime.now(),
    );
    _marketLookupCache[itemId] = lookup;
    return lookup;
  }

  void _pruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _staleRetention;
    _postLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _chatLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _jobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _tutoringLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _marketLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _trimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= _maxLookupEntries) return;
      final entries = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - _maxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(entries[i].key);
      }
    }

    trimMap<NotifyPostLookup>(_postLookupCache, (v) => v.cachedAt);
    trimMap<NotifyChatLookup>(_chatLookupCache, (v) => v.cachedAt);
    trimMap<NotifyJobLookup>(_jobLookupCache, (v) => v.cachedAt);
    trimMap<NotifyTutoringLookup>(_tutoringLookupCache, (v) => v.cachedAt);
    trimMap<NotifyMarketLookup>(_marketLookupCache, (v) => v.cachedAt);
  }
}
