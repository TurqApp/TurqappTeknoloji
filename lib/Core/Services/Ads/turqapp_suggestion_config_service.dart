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
