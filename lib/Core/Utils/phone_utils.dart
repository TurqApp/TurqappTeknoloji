String phoneDigitsOnly(String raw) {
  return raw.replaceAll(RegExp(r'[^0-9]'), '');
}
