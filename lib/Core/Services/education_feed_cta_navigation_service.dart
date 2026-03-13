import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';

class EducationFeedCtaNavigationService {
  const EducationFeedCtaNavigationService();

  UserRepository get _userRepository => UserRepository.ensure();
  PracticeExamRepository get _practiceExamRepository =>
      PracticeExamRepository.ensure();
  ScholarshipRepository get _scholarshipRepository =>
      ScholarshipRepository.ensure();
  NotifyLookupRepository get _notifyLookupRepository =>
      NotifyLookupRepository.ensure();

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
    final data = await _scholarshipRepository.fetchRawById(
      docId,
      preferCache: true,
    );
    if (data == null) {
      AppSnackbar('Hata', 'Burs bulunamadı.');
      return;
    }

    final model = IndividualScholarshipsModel.fromJson(data);
    final ownerId = (data['userID'] ?? '').toString().trim();
    Map<String, dynamic> userData = <String, dynamic>{'userID': ownerId};

    if (ownerId.isNotEmpty) {
      final userDoc = await _userRepository.getUserRaw(
        ownerId,
        preferCache: true,
      );
      if (userDoc != null) {
        userData = {
          ...userDoc,
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
    final model = await _practiceExamRepository.fetchById(
      docId,
      preferCache: true,
    );
    if (model == null) {
      AppSnackbar('Hata', 'Sınav bulunamadı.');
      return;
    }

    await Get.to(() => DenemeSinaviPreview(model: model));
  }

  Future<void> _openTutoring(String docId) async {
    final lookup = await _notifyLookupRepository.getTutoringLookup(docId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Hata', 'İlan bulunamadı.');
      return;
    }
    await Get.to(() => TutoringDetail(), arguments: lookup.model);
  }

  Future<void> _openJob(String docId) async {
    final lookup = await _notifyLookupRepository.getJobLookup(docId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('Hata', 'İlan bulunamadı.');
      return;
    }
    await Get.to(() => JobDetails(model: lookup.model!));
  }
}
