import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/education_cta_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';

class EducationFeedCtaNavigationService {
  const EducationFeedCtaNavigationService();

  UserRepository get _userRepository => UserRepository.ensure();
  PracticeExamRepository get _practiceExamRepository =>
      ensurePracticeExamRepository();
  ScholarshipRepository get _scholarshipRepository =>
      ensureScholarshipRepository();
  NotifyLookupRepository get _notifyLookupRepository =>
      ensureNotifyLookupRepository();

  Future<bool> openFromInternalUrl(String url) async {
    final target = _parseInternalEducationTarget(url);
    if (target == null) {
      return false;
    }

    await openFromPostMeta({
      'ctaType': target.type,
      'ctaDocId': target.docId,
    });
    return true;
  }

  ({String label, String type, String docId}) resolveMeta(
    Map<String, dynamic> meta,
  ) {
    final rawLabel = (meta['ctaLabel'] ?? '').toString().trim();
    var type = normalizeEducationCtaType((meta['ctaType'] ?? '').toString());
    var docId = (meta['ctaDocId'] ?? '').toString().trim();
    final ctaUrl = (meta['ctaUrl'] ?? '').toString().trim();

    final target = _parseInternalEducationTarget(ctaUrl);
    if (target != null) {
      if (type.isEmpty) {
        type = target.type;
      }
      if (docId.isEmpty) {
        docId = target.docId;
      }
    }

    final label = rawLabel.isNotEmpty ? rawLabel : _defaultLabelForType(type);
    return (label: label, type: type, docId: docId);
  }

  String sanitizeCaptionText(
    String text, {
    Map<String, dynamic>? meta,
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final resolved = resolveMeta(meta ?? const <String, dynamic>{});
    final hasEducationCta =
        resolved.type.isNotEmpty || isTurqAppEducationLink(normalized);
    if (!hasEducationCta) {
      return normalized;
    }

    final blockedLabels = <String>{
      'bursu incele',
      'sınavı incele',
      'sinavı incele',
      'ilanı incele',
      'ilani incele',
      if (resolved.label.isNotEmpty) normalizeSearchText(resolved.label),
    };

    final cleanedLines =
        normalized.split('\n').map((line) => line.trim()).where((line) {
      if (line.isEmpty) {
        return false;
      }
      final lower = normalizeSearchText(line);
      if (isTurqAppEducationLink(lower)) {
        return false;
      }
      if (blockedLabels.contains(lower)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    return cleanedLines.join('\n').trim();
  }

  Future<void> openFromPostMeta(Map<String, dynamic> meta) async {
    final resolved = resolveMeta(meta);
    final type = resolved.type;
    final docId = resolved.docId;

    if (type.isEmpty || docId.isEmpty) {
      AppSnackbar('common.error'.tr, 'education_feed.content_open_failed'.tr);
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
      case 'market':
        await _openMarket(docId);
        return;
      default:
        AppSnackbar(
            'common.error'.tr, 'education_feed.content_type_unsupported'.tr);
    }
  }

  String _defaultLabelForType(String type) {
    switch (type) {
      case kEducationCtaScholarship:
        return 'education_feed.cta_scholarship'.tr;
      case kEducationCtaPracticeExam:
        return 'education_feed.cta_exam'.tr;
      case kEducationCtaTutoring:
      case kEducationCtaJob:
        return 'education_feed.cta_listing'.tr;
      case kEducationCtaMarket:
        return 'education_feed.cta_listing'.tr;
      default:
        return '';
    }
  }

  ({String type, String docId})? _parseInternalEducationTarget(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !isTurqAppUriScheme(uri.scheme)) {
      return null;
    }

    final host = normalizeSearchText(uri.host);
    final segments =
        uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();
    if (segments.isEmpty ||
        (host != 'education' && host != 'edu' && host != 'market')) {
      return null;
    }

    String type = '';
    String docId = '';
    if (host == 'market') {
      type = kEducationCtaMarket;
      docId = segments.first;
    } else if (segments.length >= 2) {
      type = segments[0];
      docId = segments[1];
    } else if (segments.first.contains(':')) {
      final parts = segments.first.split(':');
      if (parts.length >= 2) {
        type = parts.first;
        docId = parts.sublist(1).join(':');
      }
    }

    final normalizedType = normalizeEducationCtaType(type);
    final normalizedDocId = docId.trim();
    if (normalizedType.isEmpty || normalizedDocId.isEmpty) {
      return null;
    }

    return (type: normalizedType, docId: normalizedDocId);
  }

  Future<void> _openScholarship(String docId) async {
    final data = await _scholarshipRepository.fetchRawById(
      docId,
      preferCache: true,
    );
    if (data == null) {
      AppSnackbar('common.error'.tr, 'education_feed.scholarship_not_found'.tr);
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
      AppSnackbar('common.error'.tr, 'education_feed.exam_not_found'.tr);
      return;
    }

    await Get.to(() => DenemeSinaviPreview(model: model));
  }

  Future<void> _openTutoring(String docId) async {
    final lookup = await _notifyLookupRepository.getTutoringLookup(docId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.error'.tr, 'education_feed.listing_not_found'.tr);
      return;
    }
    await Get.to(() => TutoringDetail(), arguments: lookup.model);
  }

  Future<void> _openJob(String docId) async {
    final lookup = await _notifyLookupRepository.getJobLookup(docId);
    if (!lookup.exists || lookup.model == null) {
      AppSnackbar('common.error'.tr, 'education_feed.listing_not_found'.tr);
      return;
    }
    await Get.to(() => JobDetails(model: lookup.model!));
  }

  Future<void> _openMarket(String docId) async {
    final item = await MarketRepository.ensure().fetchById(
      docId,
      preferCache: true,
    );
    if (item == null) {
      AppSnackbar('common.error'.tr, 'education_feed.listing_not_found'.tr);
      return;
    }
    await Get.to(() => MarketDetailView(item: item));
  }
}
