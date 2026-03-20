import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeLocationText(String value) {
  return normalizeSearchText(value);
}

String normalizeCityText(String value) {
  var normalized = normalizeLocationText(value);
  normalized = normalized.replaceAll(' province', '');
  normalized = normalized.replaceAll(' ili', '');
  normalized = normalized.replaceAll(' il', '');
  normalized = normalized.replaceAll(' sehri', '');
  normalized = normalized.replaceAll(' şehir', '');
  return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
}
