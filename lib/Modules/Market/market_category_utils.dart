import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeMarketNodeKey(String value) => normalizeSearchText(value);

String normalizeMarketCategoryLabel(String value) {
  return normalizeSearchText(value)
      .replaceAll('&', 've')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
