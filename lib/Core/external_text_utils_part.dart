part of 'external.dart';

String getRemainingTimeText(int millis) {
  final releaseDate = DateTime.fromMillisecondsSinceEpoch(millis);
  final remaining = releaseDate.difference(DateTime.now());

  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;

  if (remaining.inDays > 0) {
    final dayStr = days.toString().padLeft(2, '0');
    return 'common.remaining_days'.trParams({'count': dayStr});
  } else if (remaining.inHours > 0) {
    final hourStr = hours.toString().padLeft(2, '0');
    return 'common.remaining_hours'.trParams({'count': hourStr});
  } else if (remaining.inMinutes > 0) {
    final minuteStr = minutes.toString().padLeft(2, '0');
    return 'common.remaining_minutes'.trParams({'count': minuteStr});
  } else {
    final secondStr = seconds.toString().padLeft(2, '0');
    return 'common.remaining_seconds'.trParams({'count': secondStr});
  }
}

String zamanFarkiniHesapla(int targetMillis) {
  final currentMillis = DateTime.now().millisecondsSinceEpoch;
  var difference = targetMillis - currentMillis;

  if (difference < 0) {
    return 'common.time_passed'.tr;
  }

  final years = difference ~/ (365 * 24 * 60 * 60 * 1000);
  difference %= (365 * 24 * 60 * 60 * 1000);
  final months = difference ~/ (30 * 24 * 60 * 60 * 1000);
  difference %= (30 * 24 * 60 * 60 * 1000);
  final days = difference ~/ (24 * 60 * 60 * 1000);

  var result = "";

  if (years > 0) {
    result += 'common.remaining_years'.trParams({'count': '$years'});
  }
  if (months > 0) {
    result += 'common.remaining_months'.trParams({'count': '$months'});
  }
  if (days > 0) {
    result += 'common.remaining_days_short'.trParams({'count': '$days'});
  }

  return result.isEmpty ? 'common.time_ready'.tr : result.trim();
}

class KilometerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');

    var formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && (newText.length - i) % 3 == 0) {
        formattedText += '.';
      }
      formattedText += newText[i];
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

int generateRandomNumber(int min, int max) {
  final random = Random();
  return min + random.nextInt(max - min);
}

String capitalize(String s) {
  return capitalizeWords(s);
}

String formatTimestampToTurkish(String timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));

  const monthKeys = [
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

  final month = monthKeys[date.month - 1].tr;
  final year = date.year.toString();

  return "$month $year";
}

String formatTimestampToTurkish2(String dateStr) {
  try {
    final date = DateFormat('dd.MM.yyyy').parseStrict(dateStr);

    const monthKeys = [
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

    return "${date.day} ${monthKeys[date.month - 1].tr} ${date.year}";
  } catch (_) {
    return dateStr;
  }
}

String formatTimestampToDate(String timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return "$day/$month/$year";
}

String capitalizeFirstLetter(String input) {
  if (input.isEmpty) {
    return input;
  }
  return input[0].toUpperCase() + input.substring(1);
}

String maskedLastName(String lastName) {
  if (lastName.isEmpty) return "";
  return lastName[0] + '*' * (lastName.length - 1);
}

String timeAgo2(num timestamp) {
  final now = DateTime.now();
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
  final difference = now.difference(dateTime);

  if (difference.inDays > 15) {
    return 'common.more_than_fifteen_days_ago'.tr;
  }
  return 'common.new'.tr;
}

String timeAgo(num timestamp) {
  final now = DateTime.now();
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'common.seconds_ago'.trParams({'count': '${difference.inSeconds}'});
  } else if (difference.inMinutes < 60) {
    return 'common.minutes_ago'.trParams({'count': '${difference.inMinutes}'});
  } else if (difference.inHours < 24) {
    return 'common.hours_ago'.trParams({'count': '${difference.inHours}'});
  } else {
    return 'common.days_ago'.trParams({'count': '${difference.inDays}'});
  }
}

String timeAgo3(num timestamp) {
  final now = DateTime.now();
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds}${'common.second_short'.tr}';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}${'common.minute_short'.tr}';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}${'common.hour_short'.tr}';
  } else {
    return '${difference.inDays}${'common.day_short'.tr}';
  }
}

String timeAgoMesaj(num timestamp) {
  final now = DateTime.now();
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    timestamp.toInt(),
    isUtc: true,
  ).toLocal();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'common.minute_ago_short'.trParams({'count': '1'});
  } else if (difference.inMinutes < 60) {
    return 'common.minute_ago_short'
        .trParams({'count': '${difference.inMinutes}'});
  } else if (difference.inHours < 24) {
    return 'common.hour_ago_short'.trParams({'count': '${difference.inHours}'});
  } else if (difference.inDays < 15) {
    return 'common.day_ago_short'.trParams({'count': '${difference.inDays}'});
  } else {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

String timeAgoMetin(num? timestamp) {
  if (timestamp == null || timestamp < 0) {
    return 'common.time_unknown'.tr;
  }

  final now = DateTime.now();
  final dateTime =
      DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).toLocal();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'common.minute_ago_short'.trParams({'count': '1'});
  } else if (difference.inMinutes < 60) {
    return 'common.minute_ago_short'
        .trParams({'count': '${difference.inMinutes}'});
  } else if (difference.inHours < 24) {
    return 'common.hour_ago_short'.trParams({'count': '${difference.inHours}'});
  } else if (difference.inDays < 5) {
    return 'common.day_ago_short'.trParams({'count': '${difference.inDays}'});
  } else {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return "$day.$month.$year";
  }
}

bool isBitisTarihiGecmis(String? bitisTarihi) {
  if (bitisTarihi == null || bitisTarihi.isEmpty) {
    return true;
  }

  try {
    final parts = bitisTarihi.split('.');
    if (parts.length != 3) {
      return true;
    }
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    final targetDate = DateTime(year, month, day);
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    return difference.isNegative;
  } catch (e) {
    print("Hata: Bitiş tarihi '$bitisTarihi' işlenemedi - $e");
    return true;
  }
}

String? remainingDaysText(String? bitisTarihi) {
  if (bitisTarihi == null || bitisTarihi.isEmpty) {
    return null;
  }

  try {
    final parts = bitisTarihi.split('.');
    if (parts.length != 3) {
      return null;
    }
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    final targetDate = DateTime(year, month, day);
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return null;
    }

    final remainingDays = difference.inDays + 1;
    if (remainingDays >= 1 && remainingDays <= 7) {
      return 'common.last_x_days'.trParams({'count': '$remainingDays'});
    }
    return null;
  } catch (e) {
    print("Hata: Bitiş tarihi '$bitisTarihi' işlenemedi - $e");
    return null;
  }
}

Future<File> convertUiImageToFile(
  ui.Image image, {
  String filename = 'cropped_image.png',
}) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer;

  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$filename';
  final file = File(filePath);

  await file.writeAsBytes(
    buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
  );
  return file;
}

String normalizeTurkishCharacters(String input) {
  return input
      .replaceAll('Ç', 'C')
      .replaceAll('ç', 'c')
      .replaceAll('Ğ', 'G')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('Ö', 'O')
      .replaceAll('ö', 'o')
      .replaceAll('Ş', 'S')
      .replaceAll('ş', 's')
      .replaceAll('Ü', 'U')
      .replaceAll('ü', 'u')
      .replaceAll('Ğ', 'G')
      .replaceAll('ı', 'i');
}

String formatPhoneNumber(String phoneNumber) {
  if (phoneNumber.length == 10) {
    return "${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}";
  }
  return phoneNumber;
}

String formatPhoneNumber2(String phoneNumber) {
  if (!phoneNumber.startsWith("+90")) {
    phoneNumber = "+90$phoneNumber";
  }

  if (phoneNumber.length == 13) {
    return "${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6, 9)} ${phoneNumber.substring(9)}";
  }

  return phoneNumber;
}

class CapitalizeInputFormatter2 extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isNotEmpty) {
      final capitalized = capitalizeWords(newValue.text);
      return newValue.copyWith(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
    return newValue;
  }
}

String turkceAyBilgisi() {
  final aylar = [
    'common.month_january'.tr,
    'common.month_february'.tr,
    'common.month_march'.tr,
    'common.month_april'.tr,
    'common.month_may'.tr,
    'common.month_june'.tr,
    'common.month_july'.tr,
    'common.month_august'.tr,
    'common.month_september'.tr,
    'common.month_october'.tr,
    'common.month_november'.tr,
    'common.month_december'.tr,
  ];

  final now = DateTime.now();
  final ayIndex = now.month - 1;
  return aylar[ayIndex];
}

String extractPngFilename(String url) {
  final regex = RegExp(r'(\d+)\.png');
  final match = regex.firstMatch(url);

  if (match != null) {
    return match.group(1)!;
  }
  return '';
}

String convertTimestampToDate(int timestamp) {
  if (timestamp < 1000000000000) {
    timestamp *= 1000;
  }

  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
}

Future<String> calculateDistanceToTarget(
  double targetLatitude,
  double targetLongitude,
) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      targetLatitude,
      targetLongitude,
    );

    return '${distance.toStringAsFixed(2)} km';
  } catch (e) {
    return 'common.location_unavailable'.trParams({'error': '$e'});
  }
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371;

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return r * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}

String capitalizeEachWord(String text) {
  return text
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${normalizeLowercase(word.substring(1))}'
            : word,
      )
      .join(' ');
}
