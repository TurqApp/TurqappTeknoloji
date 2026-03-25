part of 'post_interaction_service.dart';

enum ModerationFlagStatus {
  accepted,
  alreadyFlagged,
  disabled,
  unauthorized,
  postNotFound,
}

class ModerationFlagResult {
  const ModerationFlagResult({
    required this.status,
    this.flagCount = 0,
    this.threshold = 0,
    this.shadowHidden = false,
  });

  final ModerationFlagStatus status;
  final int flagCount;
  final int threshold;
  final bool shadowHidden;

  bool get accepted => status == ModerationFlagStatus.accepted;
  bool get alreadyFlagged => status == ModerationFlagStatus.alreadyFlagged;
  bool get isOk => accepted || alreadyFlagged;
}

class _ModerationConfigSnapshot {
  const _ModerationConfigSnapshot({
    required this.enabled,
    required this.threshold,
    required this.allowSingleFlagPerUser,
    required this.enableShadowHide,
  });

  final bool enabled;
  final int threshold;
  final bool allowSingleFlagPerUser;
  final bool enableShadowHide;
}

class _InteractionCacheEntry {
  _InteractionCacheEntry({required this.status, required this.fetchedAt});

  final Map<String, bool> status;
  final DateTime fetchedAt;

  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}
