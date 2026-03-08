import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdFeatureFlags {
  final bool adsInfrastructureEnabled;
  final bool adsAdminPanelEnabled;
  final bool adsDeliveryEnabled;
  final bool adsPublicVisibilityEnabled;
  final bool adsPreviewModeEnabled;

  const AdFeatureFlags({
    required this.adsInfrastructureEnabled,
    required this.adsAdminPanelEnabled,
    required this.adsDeliveryEnabled,
    required this.adsPublicVisibilityEnabled,
    required this.adsPreviewModeEnabled,
  });

  static const defaults = AdFeatureFlags(
    adsInfrastructureEnabled: true,
    adsAdminPanelEnabled: true,
    adsDeliveryEnabled: false,
    adsPublicVisibilityEnabled: false,
    adsPreviewModeEnabled: true,
  );

  factory AdFeatureFlags.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return AdFeatureFlags(
      adsInfrastructureEnabled: parseBool(data['adsInfrastructureEnabled'],
          fallback: defaults.adsInfrastructureEnabled),
      adsAdminPanelEnabled: parseBool(data['adsAdminPanelEnabled'],
          fallback: defaults.adsAdminPanelEnabled),
      adsDeliveryEnabled: parseBool(data['adsDeliveryEnabled'],
          fallback: defaults.adsDeliveryEnabled),
      adsPublicVisibilityEnabled: parseBool(
        data['adsPublicVisibilityEnabled'],
        fallback: defaults.adsPublicVisibilityEnabled,
      ),
      adsPreviewModeEnabled: parseBool(data['adsPreviewModeEnabled'],
          fallback: defaults.adsPreviewModeEnabled),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adsInfrastructureEnabled': adsInfrastructureEnabled,
      'adsAdminPanelEnabled': adsAdminPanelEnabled,
      'adsDeliveryEnabled': adsDeliveryEnabled,
      'adsPublicVisibilityEnabled': adsPublicVisibilityEnabled,
      'adsPreviewModeEnabled': adsPreviewModeEnabled,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  AdFeatureFlags copyWith({
    bool? adsInfrastructureEnabled,
    bool? adsAdminPanelEnabled,
    bool? adsDeliveryEnabled,
    bool? adsPublicVisibilityEnabled,
    bool? adsPreviewModeEnabled,
  }) {
    return AdFeatureFlags(
      adsInfrastructureEnabled:
          adsInfrastructureEnabled ?? this.adsInfrastructureEnabled,
      adsAdminPanelEnabled: adsAdminPanelEnabled ?? this.adsAdminPanelEnabled,
      adsDeliveryEnabled: adsDeliveryEnabled ?? this.adsDeliveryEnabled,
      adsPublicVisibilityEnabled:
          adsPublicVisibilityEnabled ?? this.adsPublicVisibilityEnabled,
      adsPreviewModeEnabled:
          adsPreviewModeEnabled ?? this.adsPreviewModeEnabled,
    );
  }
}
