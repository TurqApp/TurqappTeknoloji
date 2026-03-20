const Map<String, String> _nicknameTurkishCharMap = {
  'ç': 'c',
  'ğ': 'g',
  'ı': 'i',
  'ö': 'o',
  'ş': 's',
  'ü': 'u',
};

String normalizeNicknameInput(String raw) {
  return raw
      .trim()
      .replaceFirst(RegExp(r'^@+'), '')
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
}

String normalizeHandleInput(String raw) {
  return raw
      .trim()
      .replaceFirst(RegExp(r'^@+'), '')
      .replaceAll(RegExp(r'\s+'), '');
}

bool hasNicknameWhitespace(String raw) {
  return raw.contains(RegExp(r'\s'));
}

String normalizeProfileSlug(String raw) {
  return normalizeNicknameInput(raw);
}

String normalizeEditableNickname(String raw) {
  var normalized = normalizeNicknameInput(raw);
  for (final entry in _nicknameTurkishCharMap.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized.replaceAll(RegExp(r'[^a-z0-9._]'), '');
}
