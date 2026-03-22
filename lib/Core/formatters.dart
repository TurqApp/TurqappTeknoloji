import 'package:get/get.dart';

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
  const weekdays = <String>[
    'common.weekday_full.monday',
    'common.weekday_full.tuesday',
    'common.weekday_full.wednesday',
    'common.weekday_full.thursday',
    'common.weekday_full.friday',
    'common.weekday_full.saturday',
    'common.weekday_full.sunday',
  ];
  const months = <String>[
    'common.month_full.january',
    'common.month_full.february',
    'common.month_full.march',
    'common.month_full.april',
    'common.month_full.may',
    'common.month_full.june',
    'common.month_full.july',
    'common.month_full.august',
    'common.month_full.september',
    'common.month_full.october',
    'common.month_full.november',
    'common.month_full.december',
  ];
  final local = tarih.toLocal();
  final gunAdi = weekdays[local.weekday - 1].tr;
  final ayAdi = months[local.month - 1].tr;
  final saat = local.hour.toString().padLeft(2, '0');
  final dakika = local.minute.toString().padLeft(2, '0');
  return '${local.day} $ayAdi $gunAdi - $saat:$dakika';
}

String kacGunKaldiFormatter(DateTime hedefTarih) {
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi);

  if (fark.inMinutes <= 0) {
    return 'common.published'.tr;
  }

  final totalMinutes = fark.inMinutes;
  final gun = totalMinutes ~/ (24 * 60);
  final saat = (totalMinutes % (24 * 60)) ~/ 60;
  final dakika = totalMinutes % 60;

  if (gun > 0) {
    return '$gun${'common.day_short'.tr} $saat${'common.hour_short'.tr} $dakika${'common.minute_short'.tr}';
  }
  if (saat > 0) {
    return '$saat${'common.hour_short'.tr} $dakika${'common.minute_short'.tr}';
  }
  return '$dakika${'common.minute_short'.tr}';
}
