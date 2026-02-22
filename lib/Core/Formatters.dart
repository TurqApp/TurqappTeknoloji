class NumberFormatter {
  static String format(int? number) {
    int safeNumber = number ?? 0;

    if (safeNumber >= 1000000) {
      double million = safeNumber / 1000000;
      return "${_formatDecimal(million)}M";
    } else if (safeNumber >= 1000) {
      double thousand = safeNumber / 1000;
      return "${_formatDecimal(thousand)}B";
    } else {
      return safeNumber.toString();
    }
  }

  static String _formatDecimal(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }

    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
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
