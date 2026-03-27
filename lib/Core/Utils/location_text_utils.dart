import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeLocationText(String value) => normalizeSearchText(value);

String normalizeCityText(String value) => normalizeLocationText(value)
    .replaceAll(RegExp(r' province| ili| il| sehri| şehir'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
