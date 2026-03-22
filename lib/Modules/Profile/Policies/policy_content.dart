import 'package:flutter/cupertino.dart';

part 'policy_content_de_part.dart';
part 'policy_content_en_part.dart';
part 'policy_content_tr_part.dart';

class PolicyDocument {
  const PolicyDocument({
    required this.id,
    required this.title,
    required this.summary,
    required this.updatedAt,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final String summary;
  final String updatedAt;
  final IconData icon;
  final List<PolicySection> sections;
}

class PolicySection {
  const PolicySection({
    required this.title,
    this.body = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> body;
  final List<String> bullets;
}

List<PolicyDocument> localizedTurqAppPolicies(String? languageCode) {
  switch (languageCode) {
    case 'en':
      return _englishPolicies;
    case 'de':
      return _germanPolicies;
    default:
      return _turkishPolicies;
  }
}
