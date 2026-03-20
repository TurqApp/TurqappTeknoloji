import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

const String kSocialMediaWhatsApp = 'whatsApp';
const String kSocialMediaTurqApp = 'TurqApp';

const List<String> kSocialMediaEmbeddedKeys = <String>[
  kSocialMediaTurqApp,
  'instagram',
  'facebook',
  kSocialMediaWhatsApp,
  'x',
  'youtube',
  'linkedin',
  'tiktok',
  'pinterest',
];

String socialMediaEmbeddedLogoAsset(String key) => 'assets/icons/${key}_s.webp';

String socialMediaDisplayTitleForKey(String key) {
  switch (normalizeSocialMediaEmbeddedKey(key)) {
    case kSocialMediaWhatsApp:
      return 'WhatsApp';
    case 'instagram':
      return 'Instagram';
    case 'facebook':
      return 'Facebook';
    case 'x':
      return 'X';
    case 'youtube':
      return 'YouTube';
    case 'linkedin':
      return 'LinkedIn';
    case 'tiktok':
      return 'TikTok';
    case 'pinterest':
      return 'Pinterest';
    case kSocialMediaTurqApp:
      return 'TurqApp';
    default:
      return key.trim();
  }
}

String normalizeSocialMediaEmbeddedKey(String title) {
  switch (normalizeSearchText(title)) {
    case 'instagram':
      return 'instagram';
    case 'facebook':
      return 'facebook';
    case 'whatsapp':
      return kSocialMediaWhatsApp;
    case 'x':
      return 'x';
    case 'youtube':
      return 'youtube';
    case 'linkedin':
      return 'linkedin';
    case 'tiktok':
      return 'tiktok';
    case 'pinterest':
      return 'pinterest';
    case 'turqapp':
      return kSocialMediaTurqApp;
    default:
      return '';
  }
}
