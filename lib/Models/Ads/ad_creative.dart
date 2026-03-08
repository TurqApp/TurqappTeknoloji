import 'package:turqappv2/Models/Ads/ad_enums.dart';
import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdCreative {
  final String id;
  final String campaignId;
  final AdCreativeType type;
  final String storagePath;
  final String mediaURL;
  final String hlsMasterURL;
  final String thumbnailURL;
  final double aspectRatio;
  final int durationSec;
  final String headline;
  final String bodyText;
  final String ctaText;
  final String destinationURL;
  final AdModerationStatus moderationStatus;
  final String reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdCreative({
    required this.id,
    required this.campaignId,
    required this.type,
    required this.storagePath,
    required this.mediaURL,
    required this.hlsMasterURL,
    required this.thumbnailURL,
    required this.aspectRatio,
    required this.durationSec,
    required this.headline,
    required this.bodyText,
    required this.ctaText,
    required this.destinationURL,
    required this.moderationStatus,
    required this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => moderationStatus == AdModerationStatus.approved;

  factory AdCreative.empty() {
    final now = DateTime.now();
    return AdCreative(
      id: '',
      campaignId: '',
      type: AdCreativeType.image,
      storagePath: '',
      mediaURL: '',
      hlsMasterURL: '',
      thumbnailURL: '',
      aspectRatio: 1,
      durationSec: 0,
      headline: '',
      bodyText: '',
      ctaText: '',
      destinationURL: '',
      moderationStatus: AdModerationStatus.pending,
      reviewNotes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory AdCreative.fromMap(Map<String, dynamic> map, {required String id}) {
    return AdCreative(
      id: id,
      campaignId: (map['campaignId'] ?? '').toString(),
      type: parseEnum(
        (map['type'] ?? '').toString(),
        AdCreativeType.values,
        AdCreativeType.image,
      ),
      storagePath: (map['storagePath'] ?? '').toString(),
      mediaURL: (map['mediaURL'] ?? '').toString(),
      hlsMasterURL: (map['hlsMasterURL'] ?? '').toString(),
      thumbnailURL: (map['thumbnailURL'] ?? '').toString(),
      aspectRatio: parseDouble(map['aspectRatio'], fallback: 1),
      durationSec: parseInt(map['durationSec']),
      headline: (map['headline'] ?? '').toString(),
      bodyText: (map['bodyText'] ?? '').toString(),
      ctaText: (map['ctaText'] ?? '').toString(),
      destinationURL: (map['destinationURL'] ?? '').toString(),
      moderationStatus: parseEnum(
        (map['moderationStatus'] ?? '').toString(),
        AdModerationStatus.values,
        AdModerationStatus.pending,
      ),
      reviewNotes: (map['reviewNotes'] ?? '').toString(),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      updatedAt: parseDateTimeOrNow(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'type': enumToShort(type),
      'storagePath': storagePath,
      'mediaURL': mediaURL,
      'hlsMasterURL': hlsMasterURL,
      'thumbnailURL': thumbnailURL,
      'aspectRatio': aspectRatio,
      'durationSec': durationSec,
      'headline': headline,
      'bodyText': bodyText,
      'ctaText': ctaText,
      'destinationURL': destinationURL,
      'moderationStatus': enumToShort(moderationStatus),
      'reviewNotes': reviewNotes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  AdCreative copyWith({
    String? id,
    String? campaignId,
    AdCreativeType? type,
    String? storagePath,
    String? mediaURL,
    String? hlsMasterURL,
    String? thumbnailURL,
    double? aspectRatio,
    int? durationSec,
    String? headline,
    String? bodyText,
    String? ctaText,
    String? destinationURL,
    AdModerationStatus? moderationStatus,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdCreative(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      type: type ?? this.type,
      storagePath: storagePath ?? this.storagePath,
      mediaURL: mediaURL ?? this.mediaURL,
      hlsMasterURL: hlsMasterURL ?? this.hlsMasterURL,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      durationSec: durationSec ?? this.durationSec,
      headline: headline ?? this.headline,
      bodyText: bodyText ?? this.bodyText,
      ctaText: ctaText ?? this.ctaText,
      destinationURL: destinationURL ?? this.destinationURL,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
