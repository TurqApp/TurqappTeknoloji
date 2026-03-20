String normalizeSearchText(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

String normalizeLowercase(String input) {
  return input.trim().toLowerCase();
}

int compareNormalizedText(String a, String b) {
  return normalizeSearchText(a).compareTo(normalizeSearchText(b));
}

String capitalizeWords(String input) {
  return input
      .replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${normalizeLowercase(word.substring(1))}'
            : '',
      )
      .join(' ');
}
