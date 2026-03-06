import 'package:cloud_firestore/cloud_firestore.dart';

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

  static String _embeddedLogoByTitle(String title) {
    switch (title.trim().toLowerCase()) {
      case 'instagram':
        return 'assets/icons/instagram_s.webp';
      case 'facebook':
        return 'assets/icons/facebook_s.webp';
      case 'whatsapp':
        return 'assets/icons/whatsApp_s.webp';
      case 'x':
        return 'assets/icons/x_s.webp';
      case 'youtube':
        return 'assets/icons/youtube_s.webp';
      case 'linkedin':
        return 'assets/icons/linkedin_s.webp';
      case 'tiktok':
        return 'assets/icons/tiktok_s.webp';
      case 'pinterest':
        return 'assets/icons/pinterest_s.webp';
      case 'turqapp':
        return 'assets/icons/TurqApp_s.webp';
      default:
        return '';
    }
  }
}
