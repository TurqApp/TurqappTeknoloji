import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';

class EducationFeedCtaNavigationService {
  const EducationFeedCtaNavigationService();

  Future<bool> openFromInternalUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'turqapp') {
      return false;
    }

    final host = uri.host.toLowerCase().trim();
    final segments =
        uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();
    if (segments.isEmpty) {
      return false;
    }

    String type = '';
    String docId = '';

    if (host == 'education' || host == 'edu') {
      if (segments.length >= 2) {
        type = segments[0];
        docId = segments[1];
      } else if (segments.first.contains(':')) {
        final parts = segments.first.split(':');
        if (parts.length >= 2) {
          type = parts.first;
          docId = parts.sublist(1).join(':');
        }
      }
    }

    final normalizedType = _normalizeType(type);
    final normalizedDocId = docId.trim();
    if (normalizedType.isEmpty || normalizedDocId.isEmpty) {
      return false;
    }

    await openFromPostMeta({
      'ctaType': normalizedType,
      'ctaDocId': normalizedDocId,
    });
    return true;
  }

  Future<void> openFromPostMeta(Map<String, dynamic> meta) async {
    final type = _normalizeType((meta['ctaType'] ?? '').toString());
    final docId = (meta['ctaDocId'] ?? '').toString().trim();

    if (type.isEmpty || docId.isEmpty) {
      AppSnackbar('Hata', 'İçerik açılamadı.');
      return;
    }

    switch (type) {
      case 'scholarship':
        await _openScholarship(docId);
        return;
      case 'practice-exam':
        await _openPracticeExam(docId);
        return;
      case 'tutoring':
        await _openTutoring(docId);
        return;
      case 'job':
        await _openJob(docId);
        return;
      default:
        AppSnackbar('Hata', 'İçerik tipi desteklenmiyor.');
    }
  }

  String _normalizeType(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'scholarship':
      case 'burs':
        return 'scholarship';
      case 'practice-exam':
      case 'practiceexam':
      case 'sinav':
      case 'online-sinav':
      case 'online_sinav':
        return 'practice-exam';
      case 'tutoring':
      case 'ozel-ders':
      case 'ozelders':
        return 'tutoring';
      case 'job':
      case 'is':
      case 'is-bul':
      case 'isbul':
        return 'job';
      default:
        return '';
    }
  }

  Future<void> _openScholarship(String docId) async {
    final doc = await ScholarshipFirestorePath.doc(docId).get();
    if (!doc.exists || doc.data() == null) {
      AppSnackbar('Hata', 'Burs bulunamadı.');
      return;
    }

    final data = doc.data()!;
    final model = IndividualScholarshipsModel.fromJson(data);
    final ownerId = (data['userID'] ?? '').toString().trim();
    Map<String, dynamic> userData = <String, dynamic>{'userID': ownerId};

    if (ownerId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        userData = {
          ...userDoc.data()!,
          'userID': ownerId,
        };
      }
    }

    await Get.to(
      () => ScholarshipDetailView(),
      arguments: {
        'model': model,
        'docId': docId,
        'scholarshipId': docId,
        'userData': userData,
      },
    );
  }

  Future<void> _openPracticeExam(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection('practiceExams')
        .doc(docId)
        .get();
    if (!doc.exists || doc.data() == null) {
      AppSnackbar('Hata', 'Sınav bulunamadı.');
      return;
    }

    final data = doc.data()!;
    final model = SinavModel(
      docID: doc.id,
      cover: (data['cover'] ?? '').toString(),
      sinavTuru: (data['sinavTuru'] ?? '').toString(),
      timeStamp: (data['timeStamp'] ?? 0) as num,
      sinavAciklama: (data['sinavAciklama'] ?? '').toString(),
      sinavAdi: (data['sinavAdi'] ?? '').toString(),
      kpssSecilenLisans: (data['kpssSecilenLisans'] ?? '').toString(),
      dersler: List<String>.from(data['dersler'] ?? const []),
      userID: (data['userID'] ?? '').toString(),
      public: (data['public'] ?? false) as bool,
      taslak: (data['taslak'] ?? false) as bool,
      soruSayilari: List<String>.from(data['soruSayilari'] ?? const []),
      bitis: (data['bitis'] ?? 0) as num,
      bitisDk: (data['bitisDk'] ?? 0) as num,
    );

    await Get.to(() => DenemeSinaviPreview(model: model));
  }

  Future<void> _openTutoring(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection('educators')
        .doc(docId)
        .get();
    if (!doc.exists || doc.data() == null) {
      AppSnackbar('Hata', 'İlan bulunamadı.');
      return;
    }

    final model = TutoringModel.fromJson(doc.data()!, doc.id);
    await Get.to(() => TutoringDetail(), arguments: model);
  }

  Future<void> _openJob(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection(JobCollection.name)
        .doc(docId)
        .get();
    if (!doc.exists || doc.data() == null) {
      AppSnackbar('Hata', 'İlan bulunamadı.');
      return;
    }

    final model = JobModel.fromMap(doc.data()!, doc.id);
    await Get.to(() => JobDetails(model: model));
  }
}
