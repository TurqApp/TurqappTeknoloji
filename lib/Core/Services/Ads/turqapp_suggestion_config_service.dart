import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';

class TurqAppSuggestionPlacement {
  const TurqAppSuggestionPlacement({
    required this.id,
    required this.title,
    required this.sliderId,
    required this.surfaceSummary,
  });

  final String id;
  final String title;
  final String sliderId;
  final String surfaceSummary;
}

class TurqAppSuggestionPlacements {
  static const TurqAppSuggestionPlacement feed = TurqAppSuggestionPlacement(
    id: 'feed',
    title: 'Feed',
    sliderId: 'ads_feed',
    surfaceSummary: 'Agenda, Classic, Seri gönderi',
  );
  static const TurqAppSuggestionPlacement profile = TurqAppSuggestionPlacement(
    id: 'profile',
    title: 'Profil',
    sliderId: 'ads_profile',
    surfaceSummary: 'Kendi profil, karşı profil, istatistiklerim',
  );
  static const TurqAppSuggestionPlacement market = TurqAppSuggestionPlacement(
    id: 'market',
    title: 'Mobil Pazar',
    sliderId: 'ads_market',
    surfaceSummary: 'Liste, grid, ilan detayı',
  );
  static const TurqAppSuggestionPlacement scholarship =
      TurqAppSuggestionPlacement(
    id: 'scholarship',
    title: 'Burs',
    sliderId: 'ads_scholarship',
    surfaceSummary: 'Akış, liste, burs detayı',
  );
  static const TurqAppSuggestionPlacement answerKey =
      TurqAppSuggestionPlacement(
    id: 'answer_key',
    title: 'Cevap Anahtarı',
    sliderId: 'ads_answer_key',
    surfaceSummary: 'Grid, liste, kitapçık önizleme, soru çözüm ekranı',
  );
  static const TurqAppSuggestionPlacement job = TurqAppSuggestionPlacement(
    id: 'job',
    title: 'İşveren',
    sliderId: 'ads_job',
    surfaceSummary: 'Grid, liste, ilan detayı',
  );
  static const TurqAppSuggestionPlacement practiceExam =
      TurqAppSuggestionPlacement(
    id: 'practice_exam',
    title: 'Online Sınav',
    sliderId: 'ads_practice_exam',
    surfaceSummary: 'Grid, liste, sınav önizleme, çıkmış sorular',
  );
  static const TurqAppSuggestionPlacement tutoring = TurqAppSuggestionPlacement(
    id: 'tutoring',
    title: 'Özel Ders',
    sliderId: 'ads_tutoring',
    surfaceSummary: 'Grid, liste',
  );

  static const List<TurqAppSuggestionPlacement> entries =
      <TurqAppSuggestionPlacement>[
    feed,
    profile,
    market,
    scholarship,
    answerKey,
    job,
    practiceExam,
    tutoring,
  ];

  static TurqAppSuggestionPlacement? byId(String placementId) {
    for (final entry in entries) {
      if (entry.id == placementId) {
        return entry;
      }
    }
    return null;
  }
}

class TopScreenSliderPlacement {
  const TopScreenSliderPlacement({
    required this.id,
    required this.title,
    required this.sliderId,
    required this.surfaceSummary,
  });

  final String id;
  final String title;
  final String sliderId;
  final String surfaceSummary;
}

class TopScreenSliderPlacements {
  static const TopScreenSliderPlacement market = TopScreenSliderPlacement(
    id: 'top_market',
    title: 'Pasaj üst slider',
    sliderId: 'market',
    surfaceSummary: 'Mobil Pazar üst alan',
  );
  static const TopScreenSliderPlacement answerKey = TopScreenSliderPlacement(
    id: 'top_answer_key',
    title: 'Cevap Anahtarı üst slider',
    sliderId: 'cevap_anahtari',
    surfaceSummary: 'Cevap Anahtarı üst alan',
  );
  static const TopScreenSliderPlacement job = TopScreenSliderPlacement(
    id: 'top_job',
    title: 'İşveren üst slider',
    sliderId: 'is_bul',
    surfaceSummary: 'İşveren üst alan',
  );
  static const TopScreenSliderPlacement practiceExam = TopScreenSliderPlacement(
    id: 'top_practice_exam',
    title: 'Online Sınav üst slider',
    sliderId: 'online_sinav',
    surfaceSummary: 'Online Sınav üst alan',
  );
  static const TopScreenSliderPlacement tutoring = TopScreenSliderPlacement(
    id: 'top_tutoring',
    title: 'Özel Ders üst slider',
    sliderId: 'ozel_ders',
    surfaceSummary: 'Özel Ders üst alan',
  );
  static const TopScreenSliderPlacement previousQuestions =
      TopScreenSliderPlacement(
    id: 'top_previous_questions',
    title: 'Çıkmış Sorular üst slider',
    sliderId: 'denemeler',
    surfaceSummary: 'Çıkmış Sorular üst alan',
  );

  static const List<TopScreenSliderPlacement> entries =
      <TopScreenSliderPlacement>[
    market,
    answerKey,
    job,
    practiceExam,
    tutoring,
    previousQuestions,
  ];
}

class SliderRuntimeSummary {
  const SliderRuntimeSummary({
    required this.totalItems,
    required this.activeItems,
    required this.scheduledItems,
    required this.expiredItems,
    required this.viewCount,
    required this.uniqueViewCount,
  });

  final int totalItems;
  final int activeItems;
  final int scheduledItems;
  final int expiredItems;
  final int viewCount;
  final int uniqueViewCount;

  bool get hasActiveItems => activeItems > 0;
}

class TurqAppSuggestionConfig {
  const TurqAppSuggestionConfig({
    required this.placementId,
    required this.title,
    required this.sliderId,
    required this.headline,
    required this.body,
  });

  static const String defaultHeadline = 'Fırsat, gelişim ve ihtiyaç aynı yerde';
  static const String defaultBody =
      'TurqApp içindeki fırsatları öne çıkarıyoruz.';

  final String placementId;
  final String title;
  final String sliderId;
  final String headline;
  final String body;

  factory TurqAppSuggestionConfig.defaultsFor(
    TurqAppSuggestionPlacement placement,
  ) {
    return TurqAppSuggestionConfig(
      placementId: placement.id,
      title: placement.title,
      sliderId: placement.sliderId,
      headline: defaultHeadline,
      body: defaultBody,
    );
  }

  factory TurqAppSuggestionConfig.fromMap(
    Map<String, dynamic> data,
    TurqAppSuggestionPlacement placement,
  ) {
    return TurqAppSuggestionConfig(
      placementId: placement.id,
      title: (data['title'] ?? '').toString().trim().isEmpty
          ? placement.title
          : (data['title'] ?? '').toString().trim(),
      sliderId: (data['sliderId'] ?? '').toString().trim().isEmpty
          ? placement.sliderId
          : (data['sliderId'] ?? '').toString().trim(),
      headline: (data['headline'] ?? '').toString().trim().isEmpty
          ? defaultHeadline
          : (data['headline'] ?? '').toString().trim(),
      body: (data['body'] ?? '').toString().trim().isEmpty
          ? defaultBody
          : (data['body'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placementId': placementId,
      'title': title,
      'sliderId': sliderId,
      'headline': headline,
      'body': body,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class TurqAppSuggestionConfigService {
  TurqAppSuggestionConfigService._();

  static final TurqAppSuggestionConfigService instance =
      TurqAppSuggestionConfigService._();
  static const Duration _ttl = Duration(minutes: 10);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, _CachedTurqAppSuggestionConfig> _cache =
      <String, _CachedTurqAppSuggestionConfig>{};
  final Map<String, Future<TurqAppSuggestionConfig>> _pendingReads =
      <String, Future<TurqAppSuggestionConfig>>{};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AdsCollections.surfaceSlots);

  Future<TurqAppSuggestionConfig> getConfig(
    String placementId, {
    bool forceRefresh = false,
  }) {
    final placement = TurqAppSuggestionPlacements.byId(placementId);
    if (placement == null) {
      return Future<TurqAppSuggestionConfig>.value(
        TurqAppSuggestionConfig(
          placementId: placementId,
          title: placementId,
          sliderId: 'ads_$placementId',
          headline: TurqAppSuggestionConfig.defaultHeadline,
          body: TurqAppSuggestionConfig.defaultBody,
        ),
      );
    }

    final cached = _cache[placementId];
    if (!forceRefresh && cached != null && cached.isFresh) {
      return Future<TurqAppSuggestionConfig>.value(cached.config);
    }

    final pending = _pendingReads[placementId];
    if (!forceRefresh && pending != null) {
      return pending;
    }

    final future = _readRemoteConfig(placement);
    _pendingReads[placementId] = future;
    return future.whenComplete(() {
      _pendingReads.remove(placementId);
    });
  }

  Future<Map<String, TurqAppSuggestionConfig>> loadAll({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final allFresh = !forceRefresh &&
        TurqAppSuggestionPlacements.entries.every((placement) {
          final cached = _cache[placement.id];
          return cached != null && cached.isFresh;
        });
    if (allFresh) {
      return <String, TurqAppSuggestionConfig>{
        for (final entry in TurqAppSuggestionPlacements.entries)
          entry.id: _cache[entry.id]!.config,
      };
    }

    try {
      final snapshot = await _collection.get(
        const GetOptions(source: Source.serverAndCache),
      );
      final byId = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
      final resolved = <String, TurqAppSuggestionConfig>{};
      for (final placement in TurqAppSuggestionPlacements.entries) {
        final config = byId.containsKey(placement.id)
            ? TurqAppSuggestionConfig.fromMap(byId[placement.id]!, placement)
            : TurqAppSuggestionConfig.defaultsFor(placement);
        resolved[placement.id] = config;
        _cache[placement.id] = _CachedTurqAppSuggestionConfig(
          config: config,
          fetchedAt: now,
        );
      }
      return resolved;
    } catch (_) {
      return <String, TurqAppSuggestionConfig>{
        for (final placement in TurqAppSuggestionPlacements.entries)
          placement.id: _cache[placement.id]?.config ??
              TurqAppSuggestionConfig.defaultsFor(placement),
      };
    }
  }

  Future<void> saveConfig(TurqAppSuggestionConfig config) async {
    await _collection.doc(config.placementId).set(
          config.toMap(),
          SetOptions(merge: true),
        );
    _cache[config.placementId] = _CachedTurqAppSuggestionConfig(
      config: config,
      fetchedAt: DateTime.now(),
    );
  }

  Future<bool> hasSliderItems(String sliderId) async {
    final snapshot = await _firestore
        .collection('sliders')
        .doc(sliderId)
        .collection('items')
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.isNotEmpty;
  }

  Future<SliderRuntimeSummary> getSliderSummary(String sliderId) async {
    final snapshot = await _firestore
        .collection('sliders')
        .doc(sliderId)
        .collection('items')
        .get(const GetOptions(source: Source.serverAndCache));
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    var activeItems = 0;
    var scheduledItems = 0;
    var expiredItems = 0;
    var viewCount = 0;
    var uniqueViewCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final startDate = _readDateMs(data['startDate']);
      final endDate = _readDateMs(data['endDate']);
      final startsLater = startDate > 0 && startDate > nowMs;
      final ended = endDate > 0 && endDate < nowMs;
      if (startsLater) {
        scheduledItems++;
      } else if (ended) {
        expiredItems++;
      } else {
        activeItems++;
      }
      viewCount += (data['viewCount'] as num?)?.toInt() ?? 0;
      uniqueViewCount += (data['uniqueViewCount'] as num?)?.toInt() ?? 0;
    }

    return SliderRuntimeSummary(
      totalItems: snapshot.docs.length,
      activeItems: activeItems,
      scheduledItems: scheduledItems,
      expiredItems: expiredItems,
      viewCount: viewCount,
      uniqueViewCount: uniqueViewCount,
    );
  }

  Future<TurqAppSuggestionConfig> _readRemoteConfig(
    TurqAppSuggestionPlacement placement,
  ) async {
    try {
      final snapshot = await _collection
          .doc(placement.id)
          .get(const GetOptions(source: Source.serverAndCache));
      final config = snapshot.exists
          ? TurqAppSuggestionConfig.fromMap(snapshot.data()!, placement)
          : TurqAppSuggestionConfig.defaultsFor(placement);
      _cache[placement.id] = _CachedTurqAppSuggestionConfig(
        config: config,
        fetchedAt: DateTime.now(),
      );
      return config;
    } catch (_) {
      return _cache[placement.id]?.config ??
          TurqAppSuggestionConfig.defaultsFor(placement);
    }
  }

  int _readDateMs(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final date = DateTime.tryParse(value);
      if (date != null) return date.millisecondsSinceEpoch;
    }
    return 0;
  }
}

class _CachedTurqAppSuggestionConfig {
  const _CachedTurqAppSuggestionConfig({
    required this.config,
    required this.fetchedAt,
  });

  final TurqAppSuggestionConfig config;
  final DateTime fetchedAt;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) <=
      TurqAppSuggestionConfigService._ttl;
}
