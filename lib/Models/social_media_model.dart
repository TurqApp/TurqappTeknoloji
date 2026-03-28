import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_branding.dart';

class SocialMediaModel {
  String docID;
  String logo;
  String title;
  String url;
  num sira;

  SocialMediaModel({
    required this.docID,
    required this.title,
    required this.url,
    required this.sira,
    required this.logo,
  });

  factory SocialMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();
    final rawLogo = (data['logo'] ?? '').toString();
    final resolvedLogo =
        rawLogo.trim().isNotEmpty ? rawLogo : _embeddedLogoByTitle(title);
    return SocialMediaModel(
      docID: doc.id,
      title: title,
      url: data['url'] ?? '',
      sira: data['sira'] ?? 0,
      logo: resolvedLogo,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'sira': sira,
      'logo': logo,
    };
  }

  bool get hasLogo => logo.trim().isNotEmpty;
  bool get isAssetLogo => logo.startsWith('assets/');
  int get createdAtMillis => int.tryParse(docID) ?? 0;

  static String _embeddedLogoByTitle(String title) {
    final key = normalizeSocialMediaEmbeddedKey(title);
    return key.isEmpty ? '' : socialMediaEmbeddedLogoAsset(key);
  }
}
