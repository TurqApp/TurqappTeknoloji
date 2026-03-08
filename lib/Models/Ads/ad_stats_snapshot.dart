import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdStatsSnapshot {
  final String id;
  final String campaignId;
  final DateTime date;
  final int totalImpressions;
  final int uniqueReach;
  final int clicks;
  final double ctr;
  final double spend;
  final double avgCpc;
  final double avgCpm;
  final double videoCompletionRate;

  const AdStatsSnapshot({
    required this.id,
    required this.campaignId,
    required this.date,
    required this.totalImpressions,
    required this.uniqueReach,
    required this.clicks,
    required this.ctr,
    required this.spend,
    required this.avgCpc,
    required this.avgCpm,
    required this.videoCompletionRate,
  });

  static final zero = AdStatsSnapshot(
    id: 'zero',
    campaignId: '',
    date: DateTime.fromMillisecondsSinceEpoch(0),
    totalImpressions: 0,
    uniqueReach: 0,
    clicks: 0,
    ctr: 0,
    spend: 0,
    avgCpc: 0,
    avgCpm: 0,
    videoCompletionRate: 0,
  );

  factory AdStatsSnapshot.fromMap(Map<String, dynamic> map,
      {required String id}) {
    return AdStatsSnapshot(
      id: id,
      campaignId: (map['campaignId'] ?? '').toString(),
      date: parseDateTimeOrNow(map['date']),
      totalImpressions: parseInt(map['totalImpressions']),
      uniqueReach: parseInt(map['uniqueReach']),
      clicks: parseInt(map['clicks']),
      ctr: parseDouble(map['ctr']),
      spend: parseDouble(map['spend']),
      avgCpc: parseDouble(map['avgCpc']),
      avgCpm: parseDouble(map['avgCpm']),
      videoCompletionRate: parseDouble(map['videoCompletionRate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'date': date.millisecondsSinceEpoch,
      'totalImpressions': totalImpressions,
      'uniqueReach': uniqueReach,
      'clicks': clicks,
      'ctr': ctr,
      'spend': spend,
      'avgCpc': avgCpc,
      'avgCpm': avgCpm,
      'videoCompletionRate': videoCompletionRate,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
