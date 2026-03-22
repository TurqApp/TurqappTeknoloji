import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

const String kEducationCtaScholarship = 'scholarship';
const String kEducationCtaPracticeExam = 'practice-exam';
const String kEducationCtaTutoring = 'tutoring';
const String kEducationCtaJob = 'job';
const String kEducationCtaMarket = 'market';

String normalizeEducationCtaType(String raw) {
  final value = normalizeSearchText(raw);
  switch (value) {
    case kEducationCtaScholarship:
    case 'burs':
      return kEducationCtaScholarship;
    case kEducationCtaPracticeExam:
    case 'practiceexam':
    case 'sinav':
    case 'online-sinav':
    case 'online_sinav':
      return kEducationCtaPracticeExam;
    case kEducationCtaTutoring:
    case 'ozel-ders':
    case 'ozelders':
      return kEducationCtaTutoring;
    case kEducationCtaJob:
    case 'is':
    case 'is-bul':
    case 'isbul':
      return kEducationCtaJob;
    case kEducationCtaMarket:
    case 'pasaj':
    case 'product':
    case 'urun':
      return kEducationCtaMarket;
    default:
      return '';
  }
}
