enum AdPlacementType { feed, shorts, explore }

enum AdBidType { cpm, cpc, cpv }

enum AdCampaignStatus {
  draft,
  pendingReview,
  approved,
  paused,
  active,
  ended,
  rejected,
}

enum AdBudgetType { daily, lifetime }

enum AdCreativeType { image, video, hlsVideo }

enum AdModerationStatus { pending, approved, rejected }

enum AdDeliveryRejectReason {
  featureDisabled,
  notAdminPreview,
  campaignInactive,
  scheduleMismatch,
  budgetExhausted,
  placementMismatch,
  targetingMismatch,
  creativeNotApproved,
  frequencyCapped,
  userIneligible,
}

enum AdAnalyticsEventType {
  impression,
  click,
  videoStart,
  video25,
  video50,
  video100,
  complete,
  skip,
  ctaTap,
  rejectedByTargeting,
  rejectedByBudget,
  rejectedBySchedule,
  rejectedByPlacement,
  rejectedByModeration,
}

String enumToShort(Object value) {
  return value.toString().split('.').last;
}

T parseEnum<T>(
  String? raw,
  List<T> values,
  T fallback,
) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final clean = raw.trim();
  for (final v in values) {
    if (enumToShort(v as Object) == clean) {
      return v;
    }
  }
  return fallback;
}
