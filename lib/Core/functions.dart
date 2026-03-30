import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

String kacGunKaldi(int timestampMillis) {
  final hedefTarih = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi).inDays;

  if (fark > 0) {
    return 'common.days_left'.trParams({'count': '$fark'});
  } else if (fark == 0) {
    return 'common.today'.tr;
  } else {
    return 'common.days_ago'.trParams({'count': '${fark.abs()}'});
  }
}

List<String> parseStringList(dynamic data) {
  if (data == null) return [];
  if (data is List) return data.cast<String>();
  if (data is String) return [data];
  return [];
}

String timeAgoMetin(num timestamp) {
  final now = DateTime.now();
  final dateTime =
      DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).toLocal();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return '1${'common.minute_short'.tr}';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}${'common.minute_short'.tr}';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}${'common.hour_short'.tr}';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}${'common.day_short'.tr}';
  } else {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return "$day.$month.$year";
  }
}

Future<void> getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  final currentUid = CurrentUserService.instance.effectiveUserId;
  if (currentUid.isNotEmpty) {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      await UserRepository.ensure().updateUserFields(
        currentUid,
        {
          "device": "Android ${androidInfo.model}",
          "deviceVersion": androidInfo.version.release,
        },
      );
      print("Android device info synced");
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      print("iOS device info synced");

      await UserRepository.ensure().updateUserFields(
        currentUid,
        {
          "device": "Apple ${iosInfo.modelName}",
          "deviceVersion": iosInfo.systemVersion,
        },
      );
    }
  }
}

String formatTimeStampAyYil(String timestamp) {
  // Timestamp'i int olarak al ve DateTime'a çevir
  DateTime date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));

  // Türkçe ay adları
  const monthKeys = [
    'common.month.january',
    'common.month.february',
    'common.month.march',
    'common.month.april',
    'common.month.may',
    'common.month.june',
    'common.month.july',
    'common.month.august',
    'common.month.september',
    'common.month.october',
    'common.month.november',
    'common.month.december',
  ];

  // Ay ve yıl bilgilerini al
  String month = monthKeys[date.month - 1].tr;
  String year = date.year.toString();

  // Formatlı string döndür
  return "$month $year";
}

String getRemainingTimeText(int millis) {
  DateTime releaseDate = DateTime.fromMillisecondsSinceEpoch(millis);
  Duration remaining = releaseDate.difference(DateTime.now());

  int days = remaining.inDays;
  int hours = remaining.inHours % 24;
  int minutes = remaining.inMinutes % 60;
  int seconds = remaining.inSeconds % 60;

  // Eğer 24 saatten fazla varsa, sadece gün sayısını göster
  if (remaining.inDays > 0) {
    String dayStr = days.toString().padLeft(2, '0');
    return 'common.remaining_days'.trParams({'count': dayStr});
  }
  // Eğer 1 saatten fazla varsa, sadece saat sayısını göster
  else if (remaining.inHours > 0) {
    String hourStr = hours.toString().padLeft(2, '0');
    return 'common.remaining_hours'.trParams({'count': hourStr});
  }
  // Eğer 1 saatin altında kalmışsa, dakika ve saniye gösterebiliriz
  else if (remaining.inMinutes > 0) {
    String minuteStr = minutes.toString().padLeft(2, '0');
    return 'common.remaining_minutes'.trParams({'count': minuteStr});
  }
  // Eğer 1 dakikadan az kalmışsa, saniye sayısını göster
  else {
    String secondStr = seconds.toString().padLeft(2, '0');
    return 'common.remaining_seconds'.trParams({'count': secondStr});
  }
}

void showAlertDialog(BuildContext context, String title, String desc) {
  infoAlert(
    title: title,
    message: desc,
  );
}

String capitalize(String s) {
  return capitalizeWords(s);
}

String calculateDiscountedPrice(String priceStr, int discount) {
  try {
    // "35.245 TL" -> "35245"
    final cleanStr = priceStr.replaceAll(".", "").replaceAll(" TL", "");
    final originalPrice = int.parse(cleanStr);
    final discountedPrice = (originalPrice * (100 - discount) / 100).round();
    return "${_formatPrice(discountedPrice)} TL";
  } catch (e) {
    return priceStr; // Hatalıysa orijinal fiyatı döndür
  }
}

String _formatPrice(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final reversedIndex = str.length - i - 1;
    buffer.write(str[i]);
    if (reversedIndex % 3 == 0 && i != str.length - 1) {
      buffer.write(".");
    }
  }
  return buffer.toString();
}

void closeKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);

  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    currentFocus.focusedChild!.unfocus();
  }
}

int generateRandomNumber(int min, int max) {
  final random = Random();
  return min + random.nextInt(max - min);
}

String getMusicNameFromURL(String url) {
  if (url.isEmpty) {
    return 'spotify.fallback_title'.tr;
  }

  Uri uri = Uri.parse(url);
  return uri.pathSegments.isNotEmpty
      ? uri.pathSegments.last
          .replaceAll("storymusics/", "")
          .replaceAll("GecmisMuzikler/", "")
          .replaceAll("demovideos/", "")
          .replaceAll("shorts/", "")
          .replaceAll(".mp3", "")
          .replaceAll(".m4a", "")
          .replaceAll(".mp4", "")
      : 'spotify.fallback_title'.tr;
}
// ignore_for_file: file_names
