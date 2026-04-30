import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/Ads/ads_collections.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';

class AdsRepositoryService {
  const AdsRepositoryService();

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  CollectionReference<Map<String, dynamic>> get _campaigns =>
      AppFirestore.instance.collection(AdsCollections.campaigns);

  CollectionReference<Map<String, dynamic>> get _creatives =>
      AppFirestore.instance.collection(AdsCollections.creatives);

  CollectionReference<Map<String, dynamic>> get _advertisers =>
      AppFirestore.instance.collection(AdsCollections.advertisers);

  CollectionReference<Map<String, dynamic>> get _dailyStats =>
      AppFirestore.instance.collection(AdsCollections.dailyStats);

  CollectionReference<Map<String, dynamic>> get _deliveryLogs =>
      AppFirestore.instance.collection(AdsCollections.deliveryLogs);

  Stream<List<AdCampaign>> watchCampaigns({
    AdCampaignStatus? status,
    AdPlacementType? placement,
    bool includeTest = true,
  }) {
    Query<Map<String, dynamic>> query =
        _campaigns.orderBy('updatedAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: enumToShort(status));
    }
    if (!includeTest) {
      query = query.where('isTestCampaign', isEqualTo: false);
    }
    if (placement != null) {
      query =
          query.where('placementTypes', arrayContains: enumToShort(placement));
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => AdCampaign.fromMap(d.data(), id: d.id))
          .toList(growable: false);
    });
  }

  Future<List<AdCampaign>> getCampaignsOnce() async {
    final snap = await _campaigns.orderBy('updatedAt', descending: true).get();
    return snap.docs
        .map((d) => AdCampaign.fromMap(d.data(), id: d.id))
        .toList(growable: false);
  }

  Future<String> upsertCampaign(AdCampaign campaign) async {
    final now = DateTime.now();
    if (campaign.id.isEmpty) {
      final ref = _campaigns.doc();
      await ref.set(campaign
          .copyWith(id: ref.id, updatedAt: now, createdAt: now)
          .toMap());
      return ref.id;
    }
    await _campaigns.doc(campaign.id).set(
          campaign.copyWith(updatedAt: now).toMap(),
          SetOptions(merge: true),
        );
    return campaign.id;
  }

  Future<void> updateCampaignStatus(
    String campaignId,
    AdCampaignStatus status, {
    String approvedBy = '',
  }) async {
    await _campaigns.doc(campaignId).set({
      'status': enumToShort(status),
      'approvedBy': approvedBy,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Stream<List<AdCreative>> watchCreatives(
      {String? campaignId, bool pendingOnly = false}) {
    Query<Map<String, dynamic>> query =
        _creatives.orderBy('updatedAt', descending: true);
    if (campaignId != null && campaignId.isNotEmpty) {
      query = query.where('campaignId', isEqualTo: campaignId);
    }
    if (pendingOnly) {
      query = query.where('moderationStatus',
          isEqualTo: enumToShort(AdModerationStatus.pending));
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => AdCreative.fromMap(d.data(), id: d.id))
          .toList(growable: false);
    });
  }

  Future<List<AdCreative>> getCreativesByIds(List<String> ids) async {
    if (ids.isEmpty) return const <AdCreative>[];
    final out = <AdCreative>[];
    for (final chunk in _chunk(ids, 10)) {
      final snap =
          await _creatives.where(FieldPath.documentId, whereIn: chunk).get();
      out.addAll(snap.docs.map((d) => AdCreative.fromMap(d.data(), id: d.id)));
    }
    return out;
  }

  Future<String> upsertCreative(AdCreative creative) async {
    final now = DateTime.now();
    if (creative.id.isEmpty) {
      final ref = _creatives.doc();
      await ref.set(creative
          .copyWith(id: ref.id, createdAt: now, updatedAt: now)
          .toMap());
      return ref.id;
    }
    await _creatives.doc(creative.id).set(
          creative.copyWith(updatedAt: now).toMap(),
          SetOptions(merge: true),
        );
    return creative.id;
  }

  Future<void> reviewCreative(
    String creativeId, {
    required AdModerationStatus status,
    required String note,
  }) async {
    await _creatives.doc(creativeId).set({
      'moderationStatus': enumToShort(status),
      'reviewNotes': note,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Stream<List<AdAdvertiser>> watchAdvertisers() {
    return _advertisers.orderBy('name').snapshots().map((snap) {
      return snap.docs
          .map((d) => AdAdvertiser.fromMap(d.data(), id: d.id))
          .toList(growable: false);
    });
  }

  Future<void> upsertAdvertiser(AdAdvertiser advertiser) async {
    final now = DateTime.now();
    if (advertiser.id.isEmpty) {
      final ref = _advertisers.doc();
      await ref.set(
        AdAdvertiser(
          id: ref.id,
          name: advertiser.name,
          contactEmail: advertiser.contactEmail,
          contactPhone: advertiser.contactPhone,
          active: advertiser.active,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
      return;
    }

    await _advertisers.doc(advertiser.id).set({
      ...advertiser.toMap(),
      'updatedAt': now.millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Stream<List<AdStatsSnapshot>> watchDailyStats({String? campaignId}) {
    Query<Map<String, dynamic>> query =
        _dailyStats.orderBy('date', descending: true).limit(90);
    if (campaignId != null && campaignId.isNotEmpty) {
      query = query.where('campaignId', isEqualTo: campaignId);
    }
    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => AdStatsSnapshot.fromMap(d.data(), id: d.id))
          .toList(growable: false);
    });
  }

  Future<AdStatsSnapshot?> getTodayStatsForCampaign(String campaignId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _dailyStats
        .where('campaignId', isEqualTo: campaignId)
        .where('date', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('date', isLessThan: end.millisecondsSinceEpoch)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return AdStatsSnapshot.fromMap(doc.data(), id: doc.id);
  }

  Stream<List<Map<String, dynamic>>> watchDeliveryLogs({int limit = 200}) {
    return _deliveryLogs
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList(growable: false));
  }

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final campaignsSnap = await _campaigns.get();
    final statsSnap =
        await _dailyStats.orderBy('date', descending: true).limit(30).get();

    int active = 0;
    int paused = 0;
    for (final d in campaignsSnap.docs) {
      final st = (d.data()['status'] ?? '').toString();
      if (st == enumToShort(AdCampaignStatus.active)) active++;
      if (st == enumToShort(AdCampaignStatus.paused)) paused++;
    }

    int impressions = 0;
    int clicks = 0;
    double spend = 0;
    int uniqueReach = 0;
    double videoCompletionRateSum = 0;
    int completionCount = 0;

    for (final d in statsSnap.docs) {
      final data = d.data();
      impressions += _asInt(data['totalImpressions']);
      clicks += _asInt(data['clicks']);
      spend += _asDouble(data['spend']);
      uniqueReach += _asInt(data['uniqueReach']);
      final vcr = data['videoCompletionRate'] == null
          ? null
          : _asDouble(data['videoCompletionRate']);
      if (vcr != null) {
        videoCompletionRateSum += vcr;
        completionCount++;
      }
    }

    final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;
    final avgCpc = clicks > 0 ? spend / clicks : 0;
    final avgCpm = impressions > 0 ? (spend / impressions) * 1000 : 0;
    final vcr =
        completionCount > 0 ? videoCompletionRateSum / completionCount : 0;

    return {
      'totalCampaigns': campaignsSnap.size,
      'activeCampaigns': active,
      'pausedCampaigns': paused,
      'totalImpressions': impressions,
      'uniqueReach': uniqueReach,
      'clicks': clicks,
      'ctr': ctr,
      'spend': spend,
      'avgCpc': avgCpc,
      'avgCpm': avgCpm,
      'videoCompletionRate': vcr,
    };
  }

  List<List<String>> _chunk(List<String> values, int size) {
    if (values.isEmpty) return const <List<String>>[];
    final chunks = <List<String>>[];
    for (int i = 0; i < values.length; i += size) {
      final end = (i + size < values.length) ? i + size : values.length;
      chunks.add(values.sublist(i, end));
    }
    return chunks;
  }
}
