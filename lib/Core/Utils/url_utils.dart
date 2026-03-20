import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeWebsiteUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == 'https://' || value == 'http://') {
    return '';
  }
  if (hasHttpUrlScheme(value)) {
    return value;
  }
  return 'https://$value';
}

String ensureUrlHasScheme(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return value;
  if (hasHttpUrlScheme(value)) {
    return value;
  }
  return 'https://$value';
}

bool hasHttpUrlScheme(String raw) {
  final value = raw.trim();
  return value.startsWith('http://') || value.startsWith('https://');
}

bool isTurqAppUriScheme(String raw) {
  return normalizeSearchText(raw) == 'turqapp';
}

bool isTurqAppEducationLink(String raw) {
  return normalizeSearchText(raw).contains('turqapp://education/');
}

bool isLinkedInProfileUrl(String raw) {
  final normalized = normalizeSearchText(raw);
  if (normalized.isEmpty) return true;
  return normalized.contains('linkedin.com/');
}

bool looksLikeImageUrl(String raw) {
  final value = normalizeSearchText(raw);
  if (value.isEmpty) return false;
  return value.contains('.jpg') ||
      value.contains('.jpeg') ||
      value.contains('.png') ||
      value.contains('.webp') ||
      value.contains('.gif') ||
      value.contains('thumbnail') ||
      value.contains('thumb');
}

bool isHlsPlaylistUrl(String raw) {
  return normalizeSearchText(raw).contains('.m3u8');
}

String buildTurqAppProfileUrl(String slugOrId) {
  return 'https://turqapp.com/u/${slugOrId.trim()}';
}
