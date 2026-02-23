import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showMapsSheetWithAdres(String adres) async {
  final encodedAdres = Uri.encodeComponent(adres);
  Get.bottomSheet(
    barrierColor: Colors.black.withAlpha(50),
    SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24)
          ),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Haritalarda Aç",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // GOOGLE MAPS
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$encodedAdres");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                Get.back();
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset("assets/icons/googlemaps.webp"),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Google Haritalar'da Aç",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // APPLE MAPS (sadece iOS'ta)
            if (Platform.isIOS)
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                      "http://maps.apple.com/?q=$encodedAdres");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/icons/applemaps.webp"),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Apple Haritalar'da Aç",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // YANDEX MAPS
            GestureDetector(
              onTap: () async {
                final yandexAppUrl = Uri.parse(
                    "yandexmaps://maps.yandex.ru/?text=$encodedAdres");
                final yandexWebUrl = Uri.parse(
                    "https://yandex.com/maps/?text=$encodedAdres");
                if (await canLaunchUrl(yandexAppUrl)) {
                  await launchUrl(yandexAppUrl, mode: LaunchMode.externalApplication);
                } else if (await canLaunchUrl(yandexWebUrl)) {
                  await launchUrl(yandexWebUrl, mode: LaunchMode.externalApplication);
                }
                Get.back();
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Image.asset("assets/icons/yandexmaps.webp"),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Yandex Haritalar'da Aç",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.white,
  );
}
