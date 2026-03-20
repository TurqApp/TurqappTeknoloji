import 'package:turqappv2/Core/Utils/bool_utils.dart';

class ModerationConfigModel {
  final bool enabled;
  final int blackBadgeFlagThreshold;
  final bool allowSingleFlagPerUser;
  final bool enableShadowHide;
  final bool notifyOwnerOnAdminRemove;
  final bool notifyFlaggersOnAdminRemove;
  final bool resetFlagsOnRestore;

  const ModerationConfigModel({
    required this.enabled,
    required this.blackBadgeFlagThreshold,
    required this.allowSingleFlagPerUser,
    required this.enableShadowHide,
    required this.notifyOwnerOnAdminRemove,
    required this.notifyFlaggersOnAdminRemove,
    required this.resetFlagsOnRestore,
  });

  static const ModerationConfigModel defaults = ModerationConfigModel(
    enabled: true,
    blackBadgeFlagThreshold: 5,
    allowSingleFlagPerUser: true,
    enableShadowHide: true,
    notifyOwnerOnAdminRemove: true,
    notifyFlaggersOnAdminRemove: true,
    resetFlagsOnRestore: true,
  );

  factory ModerationConfigModel.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return defaults;
    }
    return ModerationConfigModel(
      enabled: _asBool(raw['enabled'], defaults.enabled),
      blackBadgeFlagThreshold: _asInt(
        raw['blackBadgeFlagThreshold'],
        defaults.blackBadgeFlagThreshold,
      ),
      allowSingleFlagPerUser: _asBool(
        raw['allowSingleFlagPerUser'],
        defaults.allowSingleFlagPerUser,
      ),
      enableShadowHide: _asBool(
        raw['enableShadowHide'],
        defaults.enableShadowHide,
      ),
      notifyOwnerOnAdminRemove: _asBool(
        raw['notifyOwnerOnAdminRemove'],
        defaults.notifyOwnerOnAdminRemove,
      ),
      notifyFlaggersOnAdminRemove: _asBool(
        raw['notifyFlaggersOnAdminRemove'],
        defaults.notifyFlaggersOnAdminRemove,
      ),
      resetFlagsOnRestore: _asBool(
        raw['resetFlagsOnRestore'],
        defaults.resetFlagsOnRestore,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'blackBadgeFlagThreshold': blackBadgeFlagThreshold,
      'allowSingleFlagPerUser': allowSingleFlagPerUser,
      'enableShadowHide': enableShadowHide,
      'notifyOwnerOnAdminRemove': notifyOwnerOnAdminRemove,
      'notifyFlaggersOnAdminRemove': notifyFlaggersOnAdminRemove,
      'resetFlagsOnRestore': resetFlagsOnRestore,
    };
  }

  ModerationConfigModel copyWith({
    bool? enabled,
    int? blackBadgeFlagThreshold,
    bool? allowSingleFlagPerUser,
    bool? enableShadowHide,
    bool? notifyOwnerOnAdminRemove,
    bool? notifyFlaggersOnAdminRemove,
    bool? resetFlagsOnRestore,
  }) {
    return ModerationConfigModel(
      enabled: enabled ?? this.enabled,
      blackBadgeFlagThreshold:
          blackBadgeFlagThreshold ?? this.blackBadgeFlagThreshold,
      allowSingleFlagPerUser:
          allowSingleFlagPerUser ?? this.allowSingleFlagPerUser,
      enableShadowHide: enableShadowHide ?? this.enableShadowHide,
      notifyOwnerOnAdminRemove:
          notifyOwnerOnAdminRemove ?? this.notifyOwnerOnAdminRemove,
      notifyFlaggersOnAdminRemove:
          notifyFlaggersOnAdminRemove ?? this.notifyFlaggersOnAdminRemove,
      resetFlagsOnRestore: resetFlagsOnRestore ?? this.resetFlagsOnRestore,
    );
  }

  static bool _asBool(dynamic raw, bool fallback) {
    return parseFlexibleBool(raw, fallback: fallback);
  }

  static int _asInt(dynamic raw, int fallback) {
    if (raw is int) return raw.clamp(1, 1000);
    if (raw is num) return raw.toInt().clamp(1, 1000);
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) return parsed.clamp(1, 1000);
    }
    return fallback;
  }
}
