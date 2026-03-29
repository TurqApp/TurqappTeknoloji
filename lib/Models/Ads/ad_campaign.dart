import 'package:turqappv2/Models/Ads/ad_enums.dart';
import 'package:turqappv2/Models/Ads/ad_model_utils.dart';
import 'package:turqappv2/Models/Ads/ad_targeting.dart';

class AdCampaign {
  final String id;
  final String advertiserId;
  final String name;
  final AdCampaignStatus status;
  final List<AdPlacementType> placementTypes;
  final AdBudgetType budgetType;
  final double totalBudget;
  final double dailyBudget;
  final double spentAmount;
  final String currency;
  final DateTime startAt;
  final DateTime endAt;
  final AdTargeting targeting;
  final List<String> creativeIds;
  final AdBidType bidType;
  final double bidAmount;
  final int priority;
  final bool isTestCampaign;
  final bool deliveryEnabled;
  final int frequencyCapPerDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String approvedBy;

  const AdCampaign({
    required this.id,
    required this.advertiserId,
    required this.name,
    required this.status,
    required this.placementTypes,
    required this.budgetType,
    required this.totalBudget,
    required this.dailyBudget,
    required this.spentAmount,
    required this.currency,
    required this.startAt,
    required this.endAt,
    required this.targeting,
    required this.creativeIds,
    required this.bidType,
    required this.bidAmount,
    required this.priority,
    required this.isTestCampaign,
    required this.deliveryEnabled,
    required this.frequencyCapPerDay,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.approvedBy,
  });

  factory AdCampaign.empty({required String createdBy}) {
    final now = DateTime.now();
    return AdCampaign(
      id: '',
      advertiserId: '',
      name: '',
      status: AdCampaignStatus.draft,
      placementTypes: const [AdPlacementType.feed],
      budgetType: AdBudgetType.daily,
      totalBudget: 0,
      dailyBudget: 0,
      spentAmount: 0,
      currency: 'TRY',
      startAt: now,
      endAt: now.add(const Duration(days: 7)),
      targeting: const AdTargeting(),
      creativeIds: const <String>[],
      bidType: AdBidType.cpm,
      bidAmount: 0,
      priority: 0,
      isTestCampaign: true,
      deliveryEnabled: false,
      frequencyCapPerDay: 3,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      approvedBy: '',
    );
  }

  factory AdCampaign.fromMap(Map<String, dynamic> map, {required String id}) {
    final placements = parseStringList(map['placementTypes'])
        .map((v) => parseEnum(v, AdPlacementType.values, AdPlacementType.feed))
        .toSet()
        .toList();

    return AdCampaign(
      id: id,
      advertiserId: (map['advertiserId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      status: parseEnum(
        (map['status'] ?? '').toString(),
        AdCampaignStatus.values,
        AdCampaignStatus.draft,
      ),
      placementTypes:
          placements.isEmpty ? const [AdPlacementType.feed] : placements,
      budgetType: parseEnum(
        (map['budgetType'] ?? '').toString(),
        AdBudgetType.values,
        AdBudgetType.daily,
      ),
      totalBudget: parseDouble(map['totalBudget']),
      dailyBudget: parseDouble(map['dailyBudget']),
      spentAmount: parseDouble(map['spentAmount']),
      currency: (map['currency'] ?? 'TRY').toString(),
      startAt: parseDateTimeOrNow(map['startAt']),
      endAt: parseDateTimeOrNow(map['endAt']),
      targeting: AdTargeting.fromMap(parseMap(map['targeting'])),
      creativeIds: parseStringList(map['creativeIds']),
      bidType: parseEnum(
        (map['bidType'] ?? '').toString(),
        AdBidType.values,
        AdBidType.cpm,
      ),
      bidAmount: parseDouble(map['bidAmount']),
      priority: parseInt(map['priority']),
      isTestCampaign: parseBool(map['isTestCampaign'], fallback: true),
      deliveryEnabled: parseBool(map['deliveryEnabled']),
      frequencyCapPerDay: parseInt(map['frequencyCapPerDay'], fallback: 3),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      updatedAt: parseDateTimeOrNow(map['updatedAt']),
      createdBy: (map['createdBy'] ?? '').toString(),
      approvedBy: (map['approvedBy'] ?? '').toString(),
    );
  }

  bool isScheduleActive(DateTime now) {
    return !now.isBefore(startAt) && !now.isAfter(endAt);
  }

  bool get isStatusDeliverable {
    return status == AdCampaignStatus.active ||
        status == AdCampaignStatus.approved;
  }

  bool isBudgetAvailable({required double dailySpent}) {
    if (budgetType == AdBudgetType.daily) {
      return dailyBudget <= 0 || dailySpent < dailyBudget;
    }
    return totalBudget <= 0 || spentAmount < totalBudget;
  }

  Map<String, dynamic> toMap() {
    return {
      'advertiserId': advertiserId,
      'name': name,
      'status': enumToShort(status),
      'placementTypes': placementTypes
          .map(enumToShort)
          .toList(growable: false),
      'budgetType': enumToShort(budgetType),
      'totalBudget': totalBudget,
      'dailyBudget': dailyBudget,
      'spentAmount': spentAmount,
      'currency': currency,
      'startAt': startAt.millisecondsSinceEpoch,
      'endAt': endAt.millisecondsSinceEpoch,
      'targeting': targeting.toMap(),
      'creativeIds': List<String>.from(creativeIds, growable: false),
      'bidType': enumToShort(bidType),
      'bidAmount': bidAmount,
      'priority': priority,
      'isTestCampaign': isTestCampaign,
      'deliveryEnabled': deliveryEnabled,
      'frequencyCapPerDay': frequencyCapPerDay,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
    };
  }

  AdCampaign copyWith({
    String? id,
    String? advertiserId,
    String? name,
    AdCampaignStatus? status,
    List<AdPlacementType>? placementTypes,
    AdBudgetType? budgetType,
    double? totalBudget,
    double? dailyBudget,
    double? spentAmount,
    String? currency,
    DateTime? startAt,
    DateTime? endAt,
    AdTargeting? targeting,
    List<String>? creativeIds,
    AdBidType? bidType,
    double? bidAmount,
    int? priority,
    bool? isTestCampaign,
    bool? deliveryEnabled,
    int? frequencyCapPerDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? approvedBy,
  }) {
    return AdCampaign(
      id: id ?? this.id,
      advertiserId: advertiserId ?? this.advertiserId,
      name: name ?? this.name,
      status: status ?? this.status,
      placementTypes: placementTypes ?? this.placementTypes,
      budgetType: budgetType ?? this.budgetType,
      totalBudget: totalBudget ?? this.totalBudget,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      spentAmount: spentAmount ?? this.spentAmount,
      currency: currency ?? this.currency,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      targeting: targeting ?? this.targeting,
      creativeIds: creativeIds ?? this.creativeIds,
      bidType: bidType ?? this.bidType,
      bidAmount: bidAmount ?? this.bidAmount,
      priority: priority ?? this.priority,
      isTestCampaign: isTestCampaign ?? this.isTestCampaign,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      frequencyCapPerDay: frequencyCapPerDay ?? this.frequencyCapPerDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}
