const String _turkishAlphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';

final Map<String, int> _turkishCharOrder = <String, int>{
  for (var i = 0; i < _turkishAlphabet.length; i++) _turkishAlphabet[i]: i,
};

int compareTurkishStrings(String a, String b) {
  final left = _normalizeTurkishForSort(a);
  final right = _normalizeTurkishForSort(b);
  final shortest = left.length < right.length ? left.length : right.length;

  for (var i = 0; i < shortest; i++) {
    final aChar = left[i];
    final bChar = right[i];
    final aRank = _turkishCharOrder[aChar] ??
        (_turkishAlphabet.length + aChar.codeUnitAt(0));
    final bRank = _turkishCharOrder[bChar] ??
        (_turkishAlphabet.length + bChar.codeUnitAt(0));
    if (aRank != bRank) {
      return aRank.compareTo(bRank);
    }
  }

  return left.length.compareTo(right.length);
}

void sortTurkishStrings(List<String> values) {
  values.sort(compareTurkishStrings);
}

String _normalizeTurkishForSort(String input) {
  final buffer = StringBuffer();
  for (final rune in input.trim().runes) {
    buffer.write(_normalizeTurkishChar(String.fromCharCode(rune)));
  }
  return buffer.toString();
}

String _normalizeTurkishChar(String char) {
  switch (char) {
    case 'A':
    case 'a':
      return 'a';
    case 'B':
    case 'b':
      return 'b';
    case 'C':
    case 'c':
      return 'c';
    case 'Ç':
    case 'ç':
      return 'ç';
    case 'D':
    case 'd':
      return 'd';
    case 'E':
    case 'e':
      return 'e';
    case 'F':
    case 'f':
      return 'f';
    case 'G':
    case 'g':
      return 'g';
    case 'Ğ':
    case 'ğ':
      return 'ğ';
    case 'H':
    case 'h':
      return 'h';
    case 'I':
    case 'ı':
      return 'ı';
    case 'İ':
    case 'i':
      return 'i';
    case 'J':
    case 'j':
      return 'j';
    case 'K':
    case 'k':
      return 'k';
    case 'L':
    case 'l':
      return 'l';
    case 'M':
    case 'm':
      return 'm';
    case 'N':
    case 'n':
      return 'n';
    case 'O':
    case 'o':
      return 'o';
    case 'Ö':
    case 'ö':
      return 'ö';
    case 'P':
    case 'p':
      return 'p';
    case 'R':
    case 'r':
      return 'r';
    case 'S':
    case 's':
      return 's';
    case 'Ş':
    case 'ş':
      return 'ş';
    case 'T':
    case 't':
      return 't';
    case 'U':
    case 'u':
      return 'u';
    case 'Ü':
    case 'ü':
      return 'ü';
    case 'V':
    case 'v':
      return 'v';
    case 'Y':
    case 'y':
      return 'y';
    case 'Z':
    case 'z':
      return 'z';
    default:
      return char.toLowerCase();
  }
}
