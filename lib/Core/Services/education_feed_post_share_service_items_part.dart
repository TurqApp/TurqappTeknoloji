part of 'education_feed_post_share_service.dart';

extension EducationFeedPostShareServiceItemsPart
    on EducationFeedPostShareService {
  Future<void> shareScholarship(
    Map<String, dynamic> scholarshipData,
  ) async {
    final burs = scholarshipData['model'];
    if (burs is! IndividualScholarshipsModel) {
      AppSnackbar(
        'common.error'.tr,
        'education_feed.share_scholarship_data_missing'.tr,
      );
      return;
    }

    final docId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString()
            .trim();
    if (docId.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'education_feed.share_scholarship_start_failed'.tr,
      );
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
      burs.bursVeren.isNotEmpty
          ? 'education_feed.scholarship_provider'
              .trParams({'provider': burs.bursVeren})
          : '',
      burs.bitisTarihi.isNotEmpty
          ? 'education_feed.application_deadline'
              .trParams({'date': burs.bitisTarihi})
          : '',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 4 / 3,
      ctaLabel: 'education_feed.cta_scholarship'.tr,
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
      model.sinavTuru.isNotEmpty
          ? 'education_feed.online_exam_type'
              .trParams({'type': model.sinavTuru})
          : '',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: model.cover,
      aspectRatio: 1,
      ctaLabel: 'education_feed.cta_exam'.tr,
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
      model.brans.isNotEmpty
          ? 'education_feed.branch_label'.trParams({'branch': model.brans})
          : '',
      '${model.sehir}/${model.ilce}',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: imageUrl,
      aspectRatio: 1,
      ctaLabel: 'education_feed.cta_listing'.tr,
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
      model.brand.isNotEmpty
          ? 'education_feed.company_label'.trParams({'company': model.brand})
          : '',
      '${model.city}/${model.town}',
    ]);

    await _shareDirectly(
      text: text,
      imageUrl: model.logo,
      aspectRatio: 1,
      ctaLabel: 'education_feed.cta_listing'.tr,
      ctaUrl: internalUrl,
      ctaType: 'job',
      ctaDocId: model.docID,
    );
  }
}
