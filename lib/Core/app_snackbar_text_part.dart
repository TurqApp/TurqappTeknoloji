part of 'app_snackbar.dart';

String _normalizeSnackbarText(String value) {
  var text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return '';

  final phraseReplacements = <String, String>{
    'Yükleme Başarısız': 'Yükleme Başarısız',
    'Yukleme Basarisiz': 'Yükleme Başarısız',
    'Talebiniz Bize Ulaştı': 'support.sent_title'.tr,
    'Tamam': 'common.done'.tr,
    'Bilgi': 'common.info'.tr,
    'Basarili': 'common.success'.tr,
    'Basarisiz': 'common.error'.tr,
    'Kopyalandi': 'common.copied'.tr,
    'Iletildi': 'chat.forwarded_title'.tr,
    'Kopyalandı': 'common.copied'.tr,
    'İletildi': 'chat.forwarded_title'.tr,
    'Gizli hesap': 'profile.private_account_title'.tr,
    'Boş Alanları Doldurunuz': 'signup.missing_info_title'.tr,
    'Bos Alanlari Doldurunuz': 'signup.missing_info_title'.tr,
    'Kod Gönderilemedi': 'signup.code_send_failed'.tr,
    'Kod Gonderilemedi': 'signup.code_send_failed'.tr,
    'Doğrulama Başarısız': 'signup.verify_failed_title'.tr,
    'Dogrulama Basarisiz': 'signup.verify_failed_title'.tr,
    'Giriş Başarısız': 'sign_in.sign_in_failed_title'.tr,
    'Giris Basarisiz': 'sign_in.sign_in_failed_title'.tr,
    'Başarılı': 'common.success'.tr,
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

  final haystack =
      '${normalizeLowercase(title)} ${normalizeLowercase(message)}';
  final errorKeywords = <String>[
    'common.error'.tr,
    'error',
    'failed',
    'could not',
    'not found',
    'fehler',
    'fehl',
    'erreur',
    'impossible',
    'errore',
    'erro',
    'ошибка',
    'не удалось',
  ].map(normalizeLowercase).toList();
  final warningKeywords = <String>[
    'common.warning'.tr,
    'warning',
    'warnung',
    'avertissement',
    'avviso',
    'предупреждение',
    'limit',
    'yetki',
    'permission',
    'berechtigung',
    'autorisation',
    'permesso',
    'разрешение',
    'topluluk kurall',
    'community rules',
    'community-regeln',
    'eksik',
    'missing',
  ].map(normalizeLowercase).toList();
  final successKeywords = <String>[
    'common.success'.tr,
    'common.done'.tr,
    'common.copied'.tr,
    'chat.forwarded_title'.tr,
    'success',
    'successful',
    'erfolgreich',
    'succes',
    'riuscita',
    'успешно',
    'copied',
    'sent',
    'saved',
    'updated',
    'kopyalandı',
    'gönderildi',
    'kaydedildi',
    'güncellendi',
  ].map(normalizeLowercase).toList();

  if (errorKeywords.any(haystack.contains)) {
    return const _AppSnackbarPalette(
      background: Color(0xFFB42318),
      border: Color(0xFFD92D20),
      iconBadge: Color(0x26FFFFFF),
      text: Colors.white,
      icon: CupertinoIcons.exclamationmark_circle,
    );
  }
  if (warningKeywords.any(haystack.contains)) {
    return const _AppSnackbarPalette(
      background: Color(0xFF9A6700),
      border: Color(0xFFB54708),
      iconBadge: Color(0x26FFFFFF),
      text: Colors.white,
      icon: CupertinoIcons.exclamationmark_triangle,
    );
  }
  if (successKeywords.any(haystack.contains)) {
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
