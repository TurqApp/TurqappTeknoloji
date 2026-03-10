import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:uuid/uuid.dart';

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

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 4 / 3,
      ctaLabel: 'Bursu İncele',
      ctaUrl: shortUrl,
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

    await _shareDirectly(
      text: text,
      imageUrl: model.cover,
      aspectRatio: 1,
      ctaLabel: 'Sınavı İncele',
      ctaUrl: shortUrl,
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

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 1,
      ctaLabel: 'İlanı İncele',
      ctaUrl: shortUrl,
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

    await _shareDirectly(
      text: text,
      imageUrl: model.logo,
      aspectRatio: 1,
      ctaLabel: 'İlanı İncele',
      ctaUrl: shortUrl,
    );
  }

  Future<void> _shareDirectly({
    required String text,
    required String imageUrl,
    required double aspectRatio,
    required String ctaLabel,
    required String ctaUrl,
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
      final loader = Get.isRegistered<GlobalLoaderController>()
          ? Get.find<GlobalLoaderController>()
          : Get.put(GlobalLoaderController());
      loader.isOn.value = true;

      try {
        final postId = const Uuid().v4();
        final now = DateTime.now().millisecondsSinceEpoch;
        final normalizedAspectRatio = double.parse(
          aspectRatio.toStringAsFixed(4),
        );
        final imageUrls = [imageUrl.trim()];
        final imgMap = imageUrls
            .map(
              (url) => {
                'url': url,
                'aspectRatio': normalizedAspectRatio,
              },
            )
            .toList();

        await FirebaseFirestore.instance.collection('Posts').doc(postId).set({
          'arsiv': false,
          'debugMode': false,
          'deletedPost': false,
          'deletedPostTime': 0,
          'flood': false,
          'floodCount': 1,
          'gizlendi': false,
          'img': imageUrls,
          'imgMap': imgMap,
          'isAd': false,
          'ad': false,
          'izBirakYayinTarihi': now,
          'stats': {
            'commentCount': 0,
            'likeCount': 0,
            'reportedCount': 0,
            'retryCount': 0,
            'savedCount': 0,
            'statsCount': 0,
          },
          'konum': '',
          'mainFlood': '',
          'metin': text,
          'reshareMap': {
            'visibility': 0,
            'ctaLabel': ctaLabel,
            'ctaUrl': ctaUrl,
          },
          'scheduledAt': 0,
          'sikayetEdildi': false,
          'stabilized': false,
          'tags': [],
          'thumbnail': imageUrl.trim(),
          'timeStamp': now,
          'userID': currentUser.uid,
          'video': '',
          'hlsStatus': 'none',
          'hlsMasterUrl': '',
          'hlsUpdatedAt': 0,
          'yorum': true,
          'yorumMap': {
            'visibility': 0,
          },
          'originalUserID': '',
          'originalPostID': '',
          'sharedAsPost': false,
        });

        final newPost = PostsModel(
          ad: false,
          arsiv: false,
          aspectRatio: normalizedAspectRatio,
          debugMode: false,
          deletedPost: false,
          deletedPostTime: 0,
          docID: postId,
          flood: false,
          floodCount: 1,
          gizlendi: false,
          img: imageUrls,
          isAd: false,
          izBirakYayinTarihi: now,
          konum: '',
          mainFlood: '',
          metin: text,
          originalPostID: '',
          originalUserID: '',
          paylasGizliligi: 0,
          reshareMap: {
            'visibility': 0,
            'ctaLabel': ctaLabel,
            'ctaUrl': ctaUrl,
          },
          scheduledAt: 0,
          sikayetEdildi: false,
          stabilized: false,
          stats: PostStats(),
          tags: const [],
          thumbnail: imageUrl.trim(),
          timeStamp: now,
          userID: currentUser.uid,
          video: '',
          hlsStatus: 'none',
          hlsMasterUrl: '',
          hlsUpdatedAt: 0,
          yorum: true,
          yorumMap: const {'visibility': 0},
        );

        if (Get.isRegistered<AgendaController>()) {
          final agendaController = Get.find<AgendaController>();
          agendaController.addUploadedPostsAtTop([newPost]);
          if (agendaController.scrollController.hasClients) {
            await agendaController.scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
            );
          }
        }

        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().getLastPostAndAddToAllPosts();
        }

        AppSnackbar('Başarılı', 'Ana sayfada paylaşıldı.');
      } catch (_) {
        AppSnackbar('Hata', 'Paylaşım tamamlanamadı.');
      } finally {
        loader.isOn.value = false;
      }
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
