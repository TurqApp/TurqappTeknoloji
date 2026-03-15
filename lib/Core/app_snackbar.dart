import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _AppSnackbarPalette {
  final Color background;
  final Color border;
  final Color iconBadge;
  final Color text;
  final IconData icon;

  const _AppSnackbarPalette({
    required this.background,
    required this.border,
    required this.iconBadge,
    required this.text,
    required this.icon,
  });
}

void AppSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Duration? duration,
  SnackPosition? snackPosition,
  EdgeInsets? margin,
  double? borderRadius,
  Widget? icon,
  Color? colorText,
  TextStyle? titleStyle,
  TextStyle? messageStyle,
}) {
  final normalizedTitle = _normalizeSnackbarText(title);
  final normalizedMessage = _normalizeSnackbarText(message);
  final palette = _resolvePalette(
    title: normalizedTitle,
    message: normalizedMessage,
    backgroundColor: backgroundColor,
  );
  final mergedTitleStyle = (titleStyle ??
          TextStyle(
            color: colorText ?? palette.text,
            fontSize: 13,
            fontFamily: "MontserratBold",
            height: 1.0,
          ))
      .copyWith(
    color: colorText ?? palette.text,
    overflow: TextOverflow.ellipsis,
  );
  final mergedMessageStyle = (messageStyle ??
          TextStyle(
            color: colorText ?? palette.text.withValues(alpha: 0.92),
            fontSize: 13,
            fontFamily: "MontserratMedium",
            height: 1.0,
          ))
      .copyWith(
    color: colorText ?? palette.text.withValues(alpha: 0.92),
    overflow: TextOverflow.ellipsis,
  );

  if (Get.isSnackbarOpen) {
    Get.closeCurrentSnackbar();
  }
  Get.snackbar(
    '',
    '',
    snackStyle: SnackStyle.FLOATING,
    titleText: const SizedBox.shrink(),
    messageText: DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.background,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: Border.all(color: palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: palette.iconBadge,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon ??
                  Icon(
                    palette.icon,
                    color: palette.text,
                    size: 16,
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: normalizedTitle, style: mergedTitleStyle),
                    if (normalizedMessage.isNotEmpty)
                      TextSpan(
                        text: '  $normalizedMessage',
                        style: mergedMessageStyle,
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    snackPosition: snackPosition ?? SnackPosition.TOP,
    duration: duration ?? const Duration(seconds: 3),
    margin: margin ?? const EdgeInsets.fromLTRB(12, 10, 12, 0),
    borderRadius: borderRadius ?? 16,
    padding: EdgeInsets.zero,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
}

String _normalizeSnackbarText(String value) {
  var text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return '';

  const phraseReplacements = <String, String>{
    'Yükleme Başarısız': 'Yükleme Başarısız',
    'Talebiniz Bize Ulaştı': 'Talebiniz Alındı',
    'Tamam': 'İşlem Tamamlandı',
    'Bilgi': 'Bilgilendirme',
    'Kopyalandı': 'Panoya Kopyalandı',
    'İletildi': 'İleti Gönderildi',
    'Gizli hesap': 'Gizli Hesap',
    'Boş Alanları Doldurunuz': 'Eksik Bilgi',
    'Kod Gönderilemedi': 'Kod Gönderilemedi',
    'Doğrulama Başarısız': 'Doğrulama Başarısız',
    'Giriş Başarısız': 'Giriş Başarısız',
    'Başarılı': 'İşlem Başarılı',
  };

  const wordReplacements = <String, String>{
    'acilmis': 'açılmış',
    'Acilmis': 'Açılmış',
    'kullanici': 'kullanıcı',
    'Kullanici': 'Kullanıcı',
    'gecmis': 'geçmiş',
    'Gecmis': 'Geçmiş',
    'secilemez': 'seçilemez',
    'Secilemez': 'Seçilemez',
    'gonder': 'gönder',
    'Gonder': 'Gönder',
    'gonderim': 'gönderim',
    'Gonderim': 'Gönderim',
    'gonderilemedi': 'gönderilemedi',
    'Gonderilemedi': 'Gönderilemedi',
    'guncellenemedi': 'güncellenemedi',
    'Guncellenemedi': 'Güncellenemedi',
    'guncellendi': 'güncellendi',
    'Guncellendi': 'Güncellendi',
    'gorsel': 'görsel',
    'Gorsel': 'Görsel',
    'ogrenci': 'öğrenci',
    'Ogrenci': 'Öğrenci',
    'uyari': 'uyarı',
    'Uyari': 'Uyarı',
    'basarili': 'başarılı',
    'Basarili': 'Başarılı',
    'basarisiz': 'başarısız',
    'Basarisiz': 'Başarısız',
    'icerik': 'içerik',
    'Icerik': 'İçerik',
    'islenemiyor': 'işlenemiyor',
    'Islenemiyor': 'İşlenemiyor',
    'lutfen': 'lütfen',
    'Lutfen': 'Lütfen',
    'baska': 'başka',
    'Baska': 'Başka',
    'deneyin': 'deneyin',
    'kaydedilemedi': 'kaydedilemedi',
    'Kaydedilemedi': 'Kaydedilemedi',
    'kaydedildi': 'kaydedildi',
    'Kaydedildi': 'Kaydedildi',
    'hikaye': 'hikâye',
    'Hikaye': 'Hikâye',
    'hikayeye': 'hikâyeye',
    'Hikayeye': 'Hikâyeye',
    'giris': 'giriş',
    'Giris': 'Giriş',
    'sifre': 'şifre',
    'Sifre': 'Şifre',
    'gecersiz': 'geçersiz',
    'Gecersiz': 'Geçersiz',
    'izin': 'izin',
    'Izin': 'İzin',
    'mikrofon izni verilmedi': 'mikrofon izni verilmedi',
  };

  phraseReplacements.forEach((source, target) {
    text = text.replaceAll(source, target);
  });

  wordReplacements.forEach((source, target) {
    text = text.replaceAll(source, target);
  });

  text = text.replaceAll('!', '');
  text = text.replaceAll(' .', '.');
  text = text.replaceAll(' ,', ',');
  text = text.trim();
  if (text.isEmpty) return '';

  text = '${text[0].toUpperCase()}${text.substring(1)}';

  if (!RegExp(r'[.!?…]$').hasMatch(text)) {
    text = '$text.';
  }

  return text;
}

_AppSnackbarPalette _resolvePalette({
  required String title,
  required String message,
  Color? backgroundColor,
}) {
  if (backgroundColor != null) {
    return _AppSnackbarPalette(
      background: backgroundColor,
      border: Colors.white.withValues(alpha: 0.12),
      iconBadge: Colors.white.withValues(alpha: 0.14),
      text: Colors.white,
      icon: CupertinoIcons.info,
    );
  }

  final haystack = '${title.toLowerCase()} ${message.toLowerCase()}';
  if (haystack.contains('hata') ||
      haystack.contains('başarısız') ||
      haystack.contains('bulunamadı') ||
      haystack.contains('kaydedilemedi') ||
      haystack.contains('güncellenemedi')) {
    return const _AppSnackbarPalette(
      background: Color(0xFFB42318),
      border: Color(0xFFD92D20),
      iconBadge: Color(0x26FFFFFF),
      text: Colors.white,
      icon: CupertinoIcons.exclamationmark_circle,
    );
  }
  if (haystack.contains('uyarı') ||
      haystack.contains('eksik') ||
      haystack.contains('limit') ||
      haystack.contains('yetki')) {
    return const _AppSnackbarPalette(
      background: Color(0xFF9A6700),
      border: Color(0xFFB54708),
      iconBadge: Color(0x26FFFFFF),
      text: Colors.white,
      icon: CupertinoIcons.exclamationmark_triangle,
    );
  }
  if (haystack.contains('başar') ||
      haystack.contains('gönderildi') ||
      haystack.contains('güncellendi') ||
      haystack.contains('kaydedildi') ||
      haystack.contains('kopyalandı')) {
    return const _AppSnackbarPalette(
      background: Color(0xFF027A48),
      border: Color(0xFF039855),
      iconBadge: Color(0x26FFFFFF),
      text: Colors.white,
      icon: CupertinoIcons.check_mark_circled,
    );
  }
  return const _AppSnackbarPalette(
    background: Color(0xFF1F2937),
    border: Color(0xFF374151),
    iconBadge: Color(0x26FFFFFF),
    text: Colors.white,
    icon: CupertinoIcons.info,
  );
}
