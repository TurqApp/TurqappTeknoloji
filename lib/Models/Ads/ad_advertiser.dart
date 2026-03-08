import 'package:turqappv2/Models/Ads/ad_model_utils.dart';

class AdAdvertiser {
  final String id;
  final String name;
  final String contactEmail;
  final String contactPhone;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdAdvertiser({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.contactPhone,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdAdvertiser.fromMap(Map<String, dynamic> map, {required String id}) {
    return AdAdvertiser(
      id: id,
      name: (map['name'] ?? '').toString(),
      contactEmail: (map['contactEmail'] ?? '').toString(),
      contactPhone: (map['contactPhone'] ?? '').toString(),
      active: parseBool(map['active'], fallback: true),
      createdAt: parseDateTimeOrNow(map['createdAt']),
      updatedAt: parseDateTimeOrNow(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'active': active,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
