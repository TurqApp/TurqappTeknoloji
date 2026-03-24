abstract final class PasajTabIds {
  static const market = 'market';
  static const jobFinder = 'job_finder';
  static const scholarships = 'scholarships';
  static const questionBank = 'question_bank';
  static const practiceExams = 'practice_exams';
  static const onlineExam = 'online_exam';
  static const answerKey = 'answer_key';
  static const tutoring = 'tutoring';
}

const List<String> pasajTabs = [
  PasajTabIds.market,
  PasajTabIds.jobFinder,
  PasajTabIds.scholarships,
  PasajTabIds.questionBank,
  PasajTabIds.practiceExams,
  PasajTabIds.onlineExam,
  PasajTabIds.answerKey,
  PasajTabIds.tutoring,
];

String pasajLegacyTitleToId(String value) {
  switch (value) {
    case 'Market':
    case 'Mabil Pazar':
      return PasajTabIds.market;
    case 'İş Bul':
    case 'İş Veren':
    case 'Is Bul':
    case 'Is Veren':
      return PasajTabIds.jobFinder;
    case 'Burslar':
      return PasajTabIds.scholarships;
    case 'Soru Bankası':
    case 'Soru Bankasi':
      return PasajTabIds.questionBank;
    case 'Deneme Sınavı':
    case 'Deneme Sınavları':
    case 'Deneme Sinavi':
    case 'Deneme Sinavlari':
    case 'Denemeler':
      return PasajTabIds.practiceExams;
    case 'Online Sınav':
    case 'Online Sinav':
      return PasajTabIds.onlineExam;
    case 'Cevap Anahtarı':
    case 'Cevap Anahtari':
      return PasajTabIds.answerKey;
    case 'Özel Ders':
    case 'Ozel Ders':
      return PasajTabIds.tutoring;
    default:
      return value;
  }
}

String pasajTitleTranslationKey(String tabId) {
  switch (tabId) {
    case PasajTabIds.market:
      return 'pasaj.tabs.market';
    case PasajTabIds.jobFinder:
      return 'pasaj.tabs.job_finder';
    case PasajTabIds.scholarships:
      return 'pasaj.tabs.scholarships';
    case PasajTabIds.questionBank:
      return 'pasaj.tabs.question_bank';
    case PasajTabIds.practiceExams:
      return 'pasaj.tabs.practice_exams';
    case PasajTabIds.onlineExam:
      return 'pasaj.tabs.online_exam';
    case PasajTabIds.answerKey:
      return 'pasaj.tabs.answer_key';
    case PasajTabIds.tutoring:
      return 'pasaj.tabs.tutoring';
    default:
      return '';
  }
}

String pasajAdminConfigKey(String tabId) {
  switch (tabId) {
    case PasajTabIds.market:
      return 'Market';
    case PasajTabIds.jobFinder:
      return 'İş Bul';
    case PasajTabIds.scholarships:
      return 'Burslar';
    case PasajTabIds.questionBank:
      return 'Soru Bankası';
    case PasajTabIds.practiceExams:
      return 'Denemeler';
    case PasajTabIds.onlineExam:
      return 'Online Sınav';
    case PasajTabIds.answerKey:
      return 'Cevap Anahtarı';
    case PasajTabIds.tutoring:
      return 'Özel Ders';
    default:
      return tabId;
  }
}
