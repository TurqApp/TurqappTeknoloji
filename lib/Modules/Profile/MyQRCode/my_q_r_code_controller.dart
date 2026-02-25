import 'dart:io';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';

import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';
import '../../../Services/firebase_my_store.dart';

class MyQRCodeController extends GetxController {
  final user = Get.find<FirebaseMyStore>();
  final ShortLinkService _shortLinkService = ShortLinkService();
  void showQrScannerModal() {
    Get.bottomSheet(
      QrScannerView(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> shareProfile() async {
    await ShareActionGuard.run(() async {
      final slug = user.nickname.value.trim().toLowerCase();
      final result = await _shortLinkService.upsertUser(
        userId: user.userID.value,
        slug: slug.isEmpty ? user.userID.value : slug,
        title: '@${user.nickname.value} - TurqApp',
        desc: 'TurqApp profilini görüntüle',
        imageUrl: user.pfImage.value,
      );
      final profileLink = (result['url'] ?? '').toString().trim().isNotEmpty
          ? (result['url'] ?? '').toString().trim()
          : 'https://turqapp.com/u/${slug.isEmpty ? user.userID.value : slug}';
      await SharePlus.instance.share(ShareParams(text: profileLink));
    });
  }

  Future<void> copyLink() async {
    final slug = user.nickname.value.trim().toLowerCase();
    final result = await _shortLinkService.upsertUser(
      userId: user.userID.value,
      slug: slug.isEmpty ? user.userID.value : slug,
      title: '@${user.nickname.value} - TurqApp',
      desc: 'TurqApp profilini görüntüle',
      imageUrl: user.pfImage.value,
    );
    final profileLink = (result['url'] ?? '').toString().trim().isNotEmpty
        ? (result['url'] ?? '').toString().trim()
        : 'https://turqapp.com/u/${slug.isEmpty ? user.userID.value : slug}';
    await Clipboard.setData(ClipboardData(text: profileLink));
    AppSnackbar("Link Kopyalandı", "Profil linki panoya kopyalandı");
  }

  Future<void> downloadQRCode() async {
    // Android 13 ve sonrası için özel medya izni
    final isAndroid13OrAbove = Platform.isAndroid;

    PermissionStatus status;

    if (isAndroid13OrAbove) {
      status = await Permission.photos
          .request(); // PNG formatı için fotoğraflar izni
    } else {
      status =
          await Permission.storage.request(); // Eski Android sürümleri için
    }

    if (!status.isGranted) {
      AppSnackbar(
          "İzin Gerekli", 'Kaydetmek için galeri erişim izni vermelisiniz.');
      return;
    }

    try {
      final qrPainter = QrPainter(
        data: Get.find<FirebaseMyStore>().userID.value,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle:
            const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: Colors.black),
        embeddedImage: await _loadLogoImage(),
        embeddedImageStyle: QrEmbeddedImageStyle(size: Size(200, 200)),
      );

      final picData = await qrPainter.toImageData(
        1000,
        format: ui.ImageByteFormat.png,
      );
      if (picData == null) {
        AppSnackbar('Hata', 'QR kod verisi oluşturulamadı.');
        return;
      }

      final Uint8List pngBytes = picData.buffer.asUint8List();
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';

      final result = await SaverGallery.saveImage(
        pngBytes,
        fileName: fileName,
        skipIfExists: false,
      );

      if (result.isSuccess) {
        AppSnackbar("Başarılı", 'QR kodu galeriye kaydedildi.');
      } else {
        AppSnackbar('Hata', 'QR kod kaydedilemedi.');
      }
    } catch (e) {
      AppSnackbar('Hata', 'İndirme sırasında hata oluştu.');
    }
  }

  Future<ui.Image?> _loadLogoImage() async {
    final byteData = await rootBundle.load("assets/images/logogradient.webp");
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
