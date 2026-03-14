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

String formatIzBirakLong(DateTime tarih) {
  const gunler = <String>[
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  const aylar = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  final local = tarih.toLocal();
  final gunAdi = gunler[local.weekday - 1];
  final ayAdi = aylar[local.month - 1];
  final saat = local.hour.toString().padLeft(2, '0');
  final dakika = local.minute.toString().padLeft(2, '0');
  return '${local.day} $ayAdi $gunAdi - $saat:$dakika';
}

String kacGunKaldiFormatter(DateTime hedefTarih) {
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi);

  if (fark.inMinutes <= 0) {
    return "Yayınlandı";
  }

  final totalMinutes = fark.inMinutes;
  final gun = totalMinutes ~/ (24 * 60);
  final saat = (totalMinutes % (24 * 60)) ~/ 60;
  final dakika = totalMinutes % 60;

  if (gun > 0) {
    return "${gun}g ${saat}sa ${dakika}dk";
  }
  if (saat > 0) {
    return "${saat}sa ${dakika}dk";
  }
  return "${dakika}dk";
}
