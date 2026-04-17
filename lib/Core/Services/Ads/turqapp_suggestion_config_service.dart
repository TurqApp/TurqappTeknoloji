import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:turqappv2/Core/Services/slider_cache_service.dart';
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
    title: 'Anasayfa',
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
    title: 'İşVeren',
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

enum ManagedAdPlacementKind {
  suggestionSlot,
  topSlider,
}

class ManagedAdPlacement {
  const ManagedAdPlacement({
    required this.id,
    required this.title,
    required this.sliderId,
    required this.surfaceSummary,
    required this.kind,
    this.suggestionPlacement,
  });

  final String id;
  final String title;
  final String sliderId;
  final String surfaceSummary;
  final ManagedAdPlacementKind kind;
  final TurqAppSuggestionPlacement? suggestionPlacement;

  bool get supportsFallbackText => suggestionPlacement != null;
}

class ManagedAdPlacements {
  static final List<ManagedAdPlacement> entries = <ManagedAdPlacement>[
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.feed.id,
      title: TurqAppSuggestionPlacements.feed.title,
      sliderId: TurqAppSuggestionPlacements.feed.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.feed.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.feed,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.profile.id,
      title: TurqAppSuggestionPlacements.profile.title,
      sliderId: TurqAppSuggestionPlacements.profile.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.profile.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.profile,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.market.id,
      title: TurqAppSuggestionPlacements.market.title,
      sliderId: TurqAppSuggestionPlacements.market.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.market.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.market,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.scholarship.id,
      title: TurqAppSuggestionPlacements.scholarship.title,
      sliderId: TurqAppSuggestionPlacements.scholarship.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.scholarship.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.scholarship,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.answerKey.id,
      title: TurqAppSuggestionPlacements.answerKey.title,
      sliderId: TurqAppSuggestionPlacements.answerKey.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.answerKey.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.answerKey,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.job.id,
      title: TurqAppSuggestionPlacements.job.title,
      sliderId: TurqAppSuggestionPlacements.job.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.job.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.job,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.practiceExam.id,
      title: TurqAppSuggestionPlacements.practiceExam.title,
      sliderId: TurqAppSuggestionPlacements.practiceExam.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.practiceExam.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.practiceExam,
    ),
    ManagedAdPlacement(
      id: TurqAppSuggestionPlacements.tutoring.id,
      title: TurqAppSuggestionPlacements.tutoring.title,
      sliderId: TurqAppSuggestionPlacements.tutoring.sliderId,
      surfaceSummary: TurqAppSuggestionPlacements.tutoring.surfaceSummary,
      kind: ManagedAdPlacementKind.suggestionSlot,
      suggestionPlacement: TurqAppSuggestionPlacements.tutoring,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.market.id,
      title: TopScreenSliderPlacements.market.title,
      sliderId: TopScreenSliderPlacements.market.sliderId,
      surfaceSummary: TopScreenSliderPlacements.market.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.answerKey.id,
      title: TopScreenSliderPlacements.answerKey.title,
      sliderId: TopScreenSliderPlacements.answerKey.sliderId,
      surfaceSummary: TopScreenSliderPlacements.answerKey.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.job.id,
      title: TopScreenSliderPlacements.job.title,
      sliderId: TopScreenSliderPlacements.job.sliderId,
      surfaceSummary: TopScreenSliderPlacements.job.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.practiceExam.id,
      title: TopScreenSliderPlacements.practiceExam.title,
      sliderId: TopScreenSliderPlacements.practiceExam.sliderId,
      surfaceSummary: TopScreenSliderPlacements.practiceExam.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.tutoring.id,
      title: TopScreenSliderPlacements.tutoring.title,
      sliderId: TopScreenSliderPlacements.tutoring.sliderId,
      surfaceSummary: TopScreenSliderPlacements.tutoring.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
    ManagedAdPlacement(
      id: TopScreenSliderPlacements.previousQuestions.id,
      title: TopScreenSliderPlacements.previousQuestions.title,
      sliderId: TopScreenSliderPlacements.previousQuestions.sliderId,
      surfaceSummary:
          TopScreenSliderPlacements.previousQuestions.surfaceSummary,
      kind: ManagedAdPlacementKind.topSlider,
    ),
  ];

  static final List<ManagedAdPlacement> suggestionEntries =
      entries.where((entry) => entry.supportsFallbackText).toList(
            growable: false,
          );

  static final List<ManagedAdPlacement> topSliderEntries =
      entries.where((entry) => !entry.supportsFallbackText).toList(
            growable: false,
          );

  static ManagedAdPlacement? byId(String placementId) {
    for (final entry in entries) {
      if (entry.id == placementId) {
        return entry;
      }
    }
    return null;
  }
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

class ManagedAdInventoryItem {
  const ManagedAdInventoryItem({
    required this.placement,
    required this.sliderSummary,
    this.config,
  });

  final ManagedAdPlacement placement;
  final SliderRuntimeSummary sliderSummary;
  final TurqAppSuggestionConfig? config;

  bool get hasManagedAd => sliderSummary.hasActiveItems;
  bool get usesFallbackCopy => placement.supportsFallbackText && !hasManagedAd;
}

class ManagedAdInventoryOverview {
  ManagedAdInventoryOverview({
    required List<ManagedAdInventoryItem> items,
    required this.totalPlacements,
    required this.suggestionPlacementCount,
    required this.topSliderPlacementCount,
    required this.activePlacementCount,
    required this.fallbackPlacementCount,
    required this.totalItems,
    required this.activeItems,
    required this.scheduledItems,
    required this.expiredItems,
    required this.viewCount,
    required this.uniqueViewCount,
  }) : items = List<ManagedAdInventoryItem>.from(
          items,
          growable: false,
        );

  final List<ManagedAdInventoryItem> items;
  final int totalPlacements;
  final int suggestionPlacementCount;
  final int topSliderPlacementCount;
  final int activePlacementCount;
  final int fallbackPlacementCount;
  final int totalItems;
  final int activeItems;
  final int scheduledItems;
  final int expiredItems;
  final int viewCount;
  final int uniqueViewCount;
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

  static String headlineForPlacement(TurqAppSuggestionPlacement placement) {
    switch (placement.id) {
      case 'feed':
        return 'Günün öne çıkanlarını tek akışta keşfet';
      case 'profile':
        return 'Profillerde öne çıkan içerikler burada';
      case 'market':
        return 'Pasajdaki seçili ilanlar seni bekliyor';
      case 'scholarship':
        return 'Başvuruya açık burs fırsatlarını kaçırma';
      case 'answer_key':
        return 'Kaynaklar ve çözümler tek yerde toplandı';
      case 'job':
        return 'Öne çıkan iş ilanlarını hızlıca incele';
      case 'practice_exam':
        return 'Denemeler ve çıkmış sorularla hazırlığını güçlendir';
      case 'tutoring':
        return 'Sana uygun özel ders ilanlarını keşfet';
    }
    return defaultHeadline;
  }

  static String bodyForPlacement(TurqAppSuggestionPlacement placement) {
    switch (placement.id) {
      case 'feed':
        return 'Gündemden fırsatlara kadar öne çıkan içerikleri senin için topladık.';
      case 'profile':
        return 'Takip ettiğin alanlara yakın önerileri ve dikkat çeken içerikleri burada bul.';
      case 'market':
        return 'Ürün, ilan ve kampüs fırsatlarını düzenli bir vitrin içinde öne çıkarıyoruz.';
      case 'scholarship':
        return 'Eğitim yolculuğuna katkı sağlayacak burs ve başvuru fırsatlarına göz at.';
      case 'answer_key':
        return 'Cevap anahtarları, kitapçıklar ve soru çözümleri için seçili içerikleri öne çıkarıyoruz.';
      case 'job':
        return 'Yeni pozisyonlar ve dikkat çeken iş fırsatları bu alanda öne çıkarılır.';
      case 'practice_exam':
        return 'Yeni denemeler, sınav önizlemeleri ve hazırlık içerikleri burada seni karşılar.';
      case 'tutoring':
        return 'Birebir ders ve destek ilanlarını daha hızlı keşfetmen için seçili içerikleri öne alıyoruz.';
    }
    return defaultBody;
  }

  factory TurqAppSuggestionConfig.defaultsFor(
    TurqAppSuggestionPlacement placement,
  ) {
    return TurqAppSuggestionConfig(
      placementId: placement.id,
      title: placement.title,
      sliderId: placement.sliderId,
      headline: headlineForPlacement(placement),
      body: bodyForPlacement(placement),
    );
  }

  factory TurqAppSuggestionConfig.fromMap(
    Map<String, dynamic> data,
    TurqAppSuggestionPlacement placement,
  ) {
    return TurqAppSuggestionConfig(
      placementId: placement.id,
      title: placement.title,
      sliderId: (data['sliderId'] ?? '').toString().trim().isEmpty
          ? placement.sliderId
          : (data['sliderId'] ?? '').toString().trim(),
      headline: (data['headline'] ?? '').toString().trim().isEmpty
          ? headlineForPlacement(placement)
          : (data['headline'] ?? '').toString().trim(),
      body: (data['body'] ?? '').toString().trim().isEmpty
          ? bodyForPlacement(placement)
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SliderCacheService _sliderCacheService = SliderCacheService();
  final Map<String, _CachedTurqAppSuggestionConfig> _cache =
      <String, _CachedTurqAppSuggestionConfig>{};
  final Map<String, Future<TurqAppSuggestionConfig>> _pendingReads =
      <String, Future<TurqAppSuggestionConfig>>{};

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

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

  Future<void> removeManagedSlider(ManagedAdPlacement placement) async {
    final sliderMeta = _firestore.collection('sliders').doc(placement.sliderId);
    final itemsSnapshot = await sliderMeta.collection('items').get();
    final batch = _firestore.batch();
    final storagePaths = <String>[];

    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
      final storagePath = (doc.data()['storagePath'] ?? '').toString().trim();
      if (storagePath.isNotEmpty) {
        storagePaths.add(storagePath);
      }
    }

    if (itemsSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }

    for (final storagePath in storagePaths) {
      try {
        await _storage.ref().child(storagePath).delete();
      } catch (_) {}
    }

    await sliderMeta.set({
      'hiddenDefaults': FieldValue.delete(),
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    await _sliderCacheService.clearResolvedItems(placement.sliderId);
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
      viewCount += _asInt(data['viewCount']);
      uniqueViewCount += _asInt(data['uniqueViewCount']);
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

  Future<ManagedAdInventoryOverview> getManagedInventoryOverview({
    bool forceRefresh = false,
  }) async {
    final configs = await loadAll(forceRefresh: forceRefresh);
    final items = await Future.wait<ManagedAdInventoryItem>(
      ManagedAdPlacements.entries.map((placement) async {
        final summary = await getSliderSummary(placement.sliderId);
        final suggestionPlacement = placement.suggestionPlacement;
        final config = suggestionPlacement == null
            ? null
            : configs[suggestionPlacement.id] ??
                TurqAppSuggestionConfig.defaultsFor(suggestionPlacement);
        return ManagedAdInventoryItem(
          placement: placement,
          sliderSummary: summary,
          config: config,
        );
      }),
    );

    var activePlacementCount = 0;
    var fallbackPlacementCount = 0;
    var totalItems = 0;
    var activeItems = 0;
    var scheduledItems = 0;
    var expiredItems = 0;
    var viewCount = 0;
    var uniqueViewCount = 0;

    for (final item in items) {
      if (item.hasManagedAd) {
        activePlacementCount++;
      }
      if (item.usesFallbackCopy) {
        fallbackPlacementCount++;
      }
      totalItems += item.sliderSummary.totalItems;
      activeItems += item.sliderSummary.activeItems;
      scheduledItems += item.sliderSummary.scheduledItems;
      expiredItems += item.sliderSummary.expiredItems;
      viewCount += item.sliderSummary.viewCount;
      uniqueViewCount += item.sliderSummary.uniqueViewCount;
    }

    return ManagedAdInventoryOverview(
      items: items,
      totalPlacements: items.length,
      suggestionPlacementCount: ManagedAdPlacements.suggestionEntries.length,
      topSliderPlacementCount: ManagedAdPlacements.topSliderEntries.length,
      activePlacementCount: activePlacementCount,
      fallbackPlacementCount: fallbackPlacementCount,
      totalItems: totalItems,
      activeItems: activeItems,
      scheduledItems: scheduledItems,
      expiredItems: expiredItems,
      viewCount: viewCount,
      uniqueViewCount: uniqueViewCount,
    );
  }

  Future<Map<String, dynamic>> getManagedDashboardMetrics({
    bool forceRefresh = false,
  }) async {
    final overview =
        await getManagedInventoryOverview(forceRefresh: forceRefresh);
    return <String, dynamic>{
      'managedPlacementCount': overview.totalPlacements,
      'managedSuggestionPlacementCount': overview.suggestionPlacementCount,
      'managedTopSliderPlacementCount': overview.topSliderPlacementCount,
      'managedActivePlacementCount': overview.activePlacementCount,
      'managedFallbackPlacementCount': overview.fallbackPlacementCount,
      'managedTotalItems': overview.totalItems,
      'managedActiveItems': overview.activeItems,
      'managedScheduledItems': overview.scheduledItems,
      'managedExpiredItems': overview.expiredItems,
      'managedViewCount': overview.viewCount,
      'managedUniqueViewCount': overview.uniqueViewCount,
    };
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
