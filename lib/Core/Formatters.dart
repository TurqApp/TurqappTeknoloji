class NumberFormatter {
  static String format(int? number) {
    final int safeNumber = number ?? 0;

    if (safeNumber >= 1000000) {
      return "${safeNumber ~/ 1000000}M";
    }

    if (safeNumber >= 1000) {
      return "${safeNumber ~/ 1000}B";
    }

    return safeNumber.toString();
  }
}

String kacGunKaldiFormatter(DateTime hedefTarih) {
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi).inDays;

  if (fark > 0) {
    return "$fark gün kaldı";
  } else if (fark == 0) {
    return "Bugün!";
  } else {
    return "${-fark} gün geçti";
  }
}
