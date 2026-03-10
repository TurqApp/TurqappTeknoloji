import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Social/UrlPostMaker/url_post_maker.dart';

class EducationFeedPostShareService {
  const EducationFeedPostShareService();

  Future<void> shareScholarship(
    Map<String, dynamic> scholarshipData,
  ) async {
    final burs = scholarshipData['model'];
    if (burs is! IndividualScholarshipsModel) {
      AppSnackbar('Hata', 'Burs verisi bulunamadı.');
      return;
    }

    final docId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString()
            .trim();
    if (docId.isEmpty) {
      AppSnackbar('Hata', 'Burs paylaşımı başlatılamadı.');
      return;
    }

    final imageUrl = _firstNonEmpty([
      burs.img,
      burs.img2,
      burs.logo,
    ]);
    final shortUrl = await _resolveUrl(
      fallbackUrl: 'https://turqapp.com/e/scholarship-${_shortTail(docId)}',
      builder: () => ShortLinkService().getEducationPublicUrl(
        shareId: 'scholarship:$docId',
        title: burs.baslik,
        desc: _shorten(
          burs.shortDescription.isNotEmpty
              ? burs.shortDescription
              : burs.aciklama,
        ),
        imageUrl: imageUrl,
      ),
    );

    final text = _lines([
      '"${burs.baslik}"',
      _shorten(
        burs.shortDescription.isNotEmpty
            ? burs.shortDescription
            : burs.aciklama,
      ),
      burs.bursVeren.isNotEmpty ? 'Burs Veren: ${burs.bursVeren}' : '',
      burs.bitisTarihi.isNotEmpty ? 'Son Başvuru: ${burs.bitisTarihi}' : '',
      '[Bursa Git]($shortUrl)',
    ]);

    await _openComposer(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 4 / 3,
    );
  }

  Future<void> sharePracticeExam(SinavModel model) async {
    final shortUrl = await _resolveUrl(
      fallbackUrl:
          'https://turqapp.com/e/practice-exam-${_shortTail(model.docID)}',
      builder: () => ShortLinkService().getEducationPublicUrl(
        shareId: 'practice-exam:${model.docID}',
        title: model.sinavAdi,
        desc: _shorten(model.sinavAciklama),
        imageUrl: model.cover.isNotEmpty ? model.cover : null,
      ),
    );

    final text = _lines([
      '"${model.sinavAdi}"',
      _shorten(model.sinavAciklama),
      model.sinavTuru.isNotEmpty ? '${model.sinavTuru} Online Sınavı' : '',
      '[Sınava Git]($shortUrl)',
    ]);

    await _openComposer(
      text: text,
      imageUrl: model.cover,
      aspectRatio: 1,
    );
  }

  Future<void> shareTutoring(TutoringModel model) async {
    final imageUrl = _firstNonEmpty(model.imgs ?? const <String>[]);
    final shortUrl = await _resolveUrl(
      fallbackUrl: 'https://turqapp.com/i/tutoring:${model.docID}',
      builder: () => ShortLinkService().getInternalEducationPublicUrl(
        shareId: 'tutoring:${model.docID}',
        title: model.baslik,
        desc: _shorten(model.aciklama),
        imageUrl: imageUrl,
      ),
    );

    final text = _lines([
      '"${model.baslik}"',
      _shorten(model.aciklama),
      model.brans.isNotEmpty ? 'Branş: ${model.brans}' : '',
      '${model.sehir}/${model.ilce}',
      '[İlana Git]($shortUrl)',
    ]);

    await _openComposer(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 1,
    );
  }

  Future<void> shareJob(JobModel model) async {
    final title =
        model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek;
    final shortUrl = await _resolveUrl(
      fallbackUrl: 'https://turqapp.com/i/job:${model.docID}',
      builder: () => ShortLinkService().getJobPublicUrl(
        jobId: model.docID,
        title: title,
        desc: _shorten(
          model.about.isNotEmpty ? model.about : model.isTanimi,
        ),
        imageUrl: model.logo.isNotEmpty ? model.logo : null,
      ),
    );

    final text = _lines([
      '"$title"',
      _shorten(model.about.isNotEmpty ? model.about : model.isTanimi),
      model.brand.isNotEmpty ? 'Şirket: ${model.brand}' : '',
      '${model.city}/${model.town}',
      '[İlana Git]($shortUrl)',
    ]);

    await _openComposer(
      text: text,
      imageUrl: model.logo,
      aspectRatio: 1,
    );
  }

  Future<void> _openComposer({
    required String text,
    required String imageUrl,
    required double aspectRatio,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar('Hata', 'Paylaşım için giriş yapmalısınız.');
      return;
    }
    if (imageUrl.trim().isEmpty) {
      AppSnackbar('Hata', 'Paylaşılacak görsel bulunamadı.');
      return;
    }

    await ShareActionGuard.run(() async {
      await Get.to(
        () => UrlPostMaker(
          video: '',
          imgs: [imageUrl],
          aspectRatio: aspectRatio,
          thumbnail: imageUrl,
          initialText: text,
        ),
      );
    });
  }

  Future<String> _resolveUrl({
    required String fallbackUrl,
    required Future<String> Function() builder,
  }) async {
    try {
      final url = (await builder()).trim();
      if (url.isNotEmpty && url != 'https://turqapp.com') {
        return url;
      }
    } catch (_) {}
    return fallbackUrl;
  }

  String _lines(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  String _shorten(String text, {int maxLength = 220}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1).trim()}…';
  }

  String _shortTail(String value) {
    return value.length >= 8 ? value.substring(0, 8) : value;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}
