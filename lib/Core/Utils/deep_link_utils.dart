import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeDeepLinkId(String raw) {
  var id = raw.trim();
  id = id.replaceAll(RegExp(r'^[^A-Za-z0-9_-]+'), '');
  id = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+$'), '');
  return id;
}

String? normalizeDeepLinkType(String raw) {
  final value = normalizeSearchText(raw);
  if (value == 'p' || value == 'post') return 'post';
  if (value == 's' || value == 'story') return 'story';
  if (value == 'u' || value == 'user' || value == 'profile') return 'user';
  if (value == 'i' || value == 'e' || value == 'edu' || value == 'education') {
    return 'edu';
  }
  if (value == 'm' || value == 'market' || value == 'product') {
    return 'market';
  }
  return null;
}
