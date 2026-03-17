import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

String kacGunKaldi(int timestampMillis) {
  final hedefTarih = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  final simdi = DateTime.now();
  final fark = hedefTarih.difference(simdi).inDays;

  if (fark > 0) {
    return "$fark gün kaldı";
  } else if (fark == 0) {
    return "Bugün!";
  } else {
    return "${fark.abs()} gün geçti";
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
  const monthNames = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  if (difference.inSeconds < 60) {
    return "1dk";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes}dk";
  } else if (difference.inHours < 24) {
    return "${difference.inHours}sa";
  } else if (difference.inDays < 7) {
    return "${difference.inDays}g";
  } else if (difference.inDays < 365) {
    final months = max(1, (difference.inDays / 30).floor());
    return "${months}ay";
  } else {
    final day = dateTime.day.toString();
    final month = monthNames[dateTime.month - 1];
    final year = (dateTime.year % 100).toString().padLeft(2, '0');
    return "$day $month $year";
  }
}

Future<void> getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  if (FirebaseAuth.instance.currentUser != null) {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      await UserRepository.ensure().updateUserFields(
        FirebaseAuth.instance.currentUser!.uid,
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
        FirebaseAuth.instance.currentUser!.uid,
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
  List<String> turkishMonths = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  // Ay ve yıl bilgilerini al
  String month = turkishMonths[date.month - 1];
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
    return '$dayStr Gün Kaldı';
  }
  // Eğer 1 saatten fazla varsa, sadece saat sayısını göster
  else if (remaining.inHours > 0) {
    String hourStr = hours.toString().padLeft(2, '0');
    return '$hourStr Saat Kaldı';
  }
  // Eğer 1 saatin altında kalmışsa, dakika ve saniye gösterebiliriz
  else if (remaining.inMinutes > 0) {
    String minuteStr = minutes.toString().padLeft(2, '0');
    return '$minuteStr Dakika Kaldı';
  }
  // Eğer 1 dakikadan az kalmışsa, saniye sayısını göster
  else {
    String secondStr = seconds.toString().padLeft(2, '0');
    return '$secondStr Saniye Kaldı';
  }
}

void showAlertDialog(BuildContext context, String title, String desc) {
  infoAlert(
    title: title,
    message: desc,
  );
}

String capitalize(String s) {
  return s
      .replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map(
        (str) => str.isNotEmpty
            ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
            : '',
      )
      .join(' ');
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
    return "Her anına uygun müzik, Spotify’da!";
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
      : "Her anına uygun müzik, Spotify’da!";
}
// ignore_for_file: file_names
