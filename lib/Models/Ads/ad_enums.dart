enum AdPlacementType {
  feed,
  shorts,
  explore,
  profile,
  market,
  scholarship,
  answerKey,
  job,
  practiceExam,
  tutoring,
  topMarket,
  topAnswerKey,
  topJob,
  topPracticeExam,
  topTutoring,
  topPreviousQuestions,
}

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

extension AdPlacementTypeLabelPart on AdPlacementType {
  String get displayName {
    switch (this) {
      case AdPlacementType.feed:
        return 'Feed';
      case AdPlacementType.shorts:
        return 'Shorts';
      case AdPlacementType.explore:
        return 'Keşfet';
      case AdPlacementType.profile:
        return 'Profil';
      case AdPlacementType.market:
        return 'Mobil Pazar';
      case AdPlacementType.scholarship:
        return 'Burs';
      case AdPlacementType.answerKey:
        return 'Cevap Anahtarı';
      case AdPlacementType.job:
        return 'İşveren';
      case AdPlacementType.practiceExam:
        return 'Online Sınav';
      case AdPlacementType.tutoring:
        return 'Özel Ders';
      case AdPlacementType.topMarket:
        return 'Pasaj üst slider';
      case AdPlacementType.topAnswerKey:
        return 'Cevap Anahtarı üst slider';
      case AdPlacementType.topJob:
        return 'İşveren üst slider';
      case AdPlacementType.topPracticeExam:
        return 'Online Sınav üst slider';
      case AdPlacementType.topTutoring:
        return 'Özel Ders üst slider';
      case AdPlacementType.topPreviousQuestions:
        return 'Çıkmış Sorular üst slider';
    }
  }
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
