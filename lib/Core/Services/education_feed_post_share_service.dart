import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
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
    final internalUrl = _buildInternalUrl(
      type: 'scholarship',
      docId: docId,
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
      '[Bursu İncele]($internalUrl)',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 4 / 3,
      ctaLabel: 'Bursu İncele',
      ctaUrl: internalUrl,
      ctaType: 'scholarship',
      ctaDocId: docId,
    );
  }

  Future<void> sharePracticeExam(SinavModel model) async {
    final internalUrl = _buildInternalUrl(
      type: 'practice-exam',
      docId: model.docID,
    );

    final text = _lines([
      '"${model.sinavAdi}"',
      _shorten(model.sinavAciklama),
      model.sinavTuru.isNotEmpty ? '${model.sinavTuru} Online Sınavı' : '',
      '[Sınavı İncele]($internalUrl)',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: model.cover,
      aspectRatio: 1,
      ctaLabel: 'Sınavı İncele',
      ctaUrl: internalUrl,
      ctaType: 'practice-exam',
      ctaDocId: model.docID,
    );
  }

  Future<void> shareTutoring(TutoringModel model) async {
    final imageUrl = _firstNonEmpty(model.imgs ?? const <String>[]);
    final internalUrl = _buildInternalUrl(
      type: 'tutoring',
      docId: model.docID,
    );

    final text = _lines([
      '"${model.baslik}"',
      _shorten(model.aciklama),
      model.brans.isNotEmpty ? 'Branş: ${model.brans}' : '',
      '${model.sehir}/${model.ilce}',
      '[İlanı İncele]($internalUrl)',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 1,
      ctaLabel: 'İlanı İncele',
      ctaUrl: internalUrl,
      ctaType: 'tutoring',
      ctaDocId: model.docID,
    );
  }

  Future<void> shareJob(JobModel model) async {
    final title =
        model.ilanBasligi.isNotEmpty ? model.ilanBasligi : model.meslek;
    final internalUrl = _buildInternalUrl(
      type: 'job',
      docId: model.docID,
    );

    final text = _lines([
      '"$title"',
      _shorten(model.about.isNotEmpty ? model.about : model.isTanimi),
      model.brand.isNotEmpty ? 'Şirket: ${model.brand}' : '',
      '${model.city}/${model.town}',
      '[İlanı İncele]($internalUrl)',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: model.logo,
      aspectRatio: 1,
      ctaLabel: 'İlanı İncele',
      ctaUrl: internalUrl,
      ctaType: 'job',
      ctaDocId: model.docID,
    );
  }

  Future<void> _shareDirectly({
    required String text,
    required String imageUrl,
    required double aspectRatio,
    required String ctaLabel,
    required String ctaUrl,
    required String ctaType,
    required String ctaDocId,
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
            'ctaType': ctaType,
            'ctaDocId': ctaDocId,
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
            'ctaType': ctaType,
            'ctaDocId': ctaDocId,
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

  String _buildInternalUrl({
    required String type,
    required String docId,
  }) {
    return 'turqapp://education/$type/${docId.trim()}';
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
