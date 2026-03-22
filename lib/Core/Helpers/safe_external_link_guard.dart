import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> confirmAndLaunchExternalUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return launchUrl(uri, mode: mode);
  }

  final confirmed = await _showExternalLinkDialog(uri);
  if (confirmed != true) return false;

  final opened = await launchUrl(uri, mode: mode);
  if (!opened) {
    AppSnackbar('Bağlantı', 'Bağlantı açılamadı.');
  }
  return opened;
}

Future<bool?> _showExternalLinkDialog(Uri uri) {
  final host = _displayHost(uri);
  return Get.dialog<bool>(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Dış Bağlantı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'MontserratBold',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bu bağlantı TurqApp dışında açılacak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.black.withValues(alpha: 0.70),
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                host,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontFamily: 'MontserratSemiBold',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'MontserratSemiBold',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Devam Et',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'MontserratSemiBold',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

String _displayHost(Uri uri) {
  final host = uri.host.trim();
  if (host.isEmpty) return uri.toString();
  return host.startsWith('www.') ? host.substring(4) : host;
}
