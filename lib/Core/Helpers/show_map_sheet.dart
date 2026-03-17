import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_action_tile.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
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
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSheetHeader(title: "Haritalarda Aç"),

            // GOOGLE MAPS
            AppSheetActionTile(
              onTap: () async {
                final url = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$encodedAdres");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                Get.back();
              },
              leading: SizedBox(
                width: 36,
                height: 36,
                child: Image.asset("assets/icons/googlemaps.webp"),
              ),
              title: "Google Haritalar'da Aç",
            ),

            // APPLE MAPS (sadece iOS'ta)
            if (Platform.isIOS)
              AppSheetActionTile(
                onTap: () async {
                  final url =
                      Uri.parse("http://maps.apple.com/?q=$encodedAdres");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Get.back();
                },
                leading: SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset("assets/icons/applemaps.webp"),
                ),
                title: "Apple Haritalar'da Aç",
              ),

            // YANDEX MAPS
            AppSheetActionTile(
              onTap: () async {
                final yandexAppUrl = Uri.parse(
                    "yandexmaps://maps.yandex.ru/?text=$encodedAdres");
                final yandexWebUrl =
                    Uri.parse("https://yandex.com/maps/?text=$encodedAdres");
                if (await canLaunchUrl(yandexAppUrl)) {
                  await launchUrl(yandexAppUrl,
                      mode: LaunchMode.externalApplication);
                } else if (await canLaunchUrl(yandexWebUrl)) {
                  await launchUrl(yandexWebUrl,
                      mode: LaunchMode.externalApplication);
                }
                Get.back();
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Image.asset("assets/icons/yandexmaps.webp"),
              ),
              title: "Yandex Haritalar'da Aç",
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.white,
  );
}
