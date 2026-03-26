import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeLocationText(String value) => normalizeSearchText(value);

String normalizeCityText(String value) => normalizeLocationText(value)
    .replaceAll(' province', '')
    .replaceAll(' ili', '')
    .replaceAll(' il', '')
    .replaceAll(' sehri', '')
    .replaceAll(' şehir', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
