const Map<String, String> kModerationReasonMap = {
  'Uyuşturucu': 'drugs',
  'Kumar': 'gambling',
  'Çıplaklık': 'nudity',
  'Dolandırıcılık': 'scam',
  'Şiddet': 'violence',
  'Spam': 'spam',
  'Diğer': 'other',
  'drugs': 'drugs',
  'gambling': 'gambling',
  'nudity': 'nudity',
  'scam': 'scam',
  'violence': 'violence',
  'spam': 'spam',
  'other': 'other',
};

const Map<String, Set<String>> kModerationReasonTitleVariants = {
  'nudity': {
    'report.reason.nudity.title',
    'çıplaklık / cinsel içerik',
    'nudity / sexual content',
    'nacktheit / sexuelle inhalte',
    'nudite / contenu sexuel',
    'nudità / contenuto sessuale',
    'nudita / contenuto sessuale',
    'нагота / сексуальный контент',
  },
  'scam': {
    'report.reason.scam.title',
    'dolandırıcılık / yanıltma',
    'scam / deception',
    'betrug / taeuschung',
    'arnaque / tromperie',
    'truffa / inganno',
    'мошенничество / обман',
  },
  'violence': {
    'report.reason.violence.title',
    'şiddet / tehdit',
    'violence / threat',
    'gewalt / drohung',
    'violence / menace',
    'violenza / minaccia',
    'насилие / угроза',
  },
  'spam': {
    'report.reason.spam.title',
    'spam / alakasız tekrar içerik',
    'spam / repetitive irrelevant content',
    'spam / wiederholende irrelevante inhalte',
    'spam / contenu repetitif non pertinent',
    'spam / contenuto ripetitivo non pertinente',
    'спам / повторяющийся нерелевантный контент',
  },
  'other': {
    'report.reason.other.title',
    'diğer',
    'other',
    'andere',
    'autre',
    'altro',
    'другое',
  },
};

String normalizeModerationReason(String reason) {
  final trimmed = reason.trim();
  if (trimmed.isEmpty) return 'other';
  final mapped =
      kModerationReasonMap[trimmed] ?? kModerationReasonMap[trimmed.toLowerCase()];
  if (mapped != null) return mapped;

  final normalized = trimmed.toLowerCase();
  for (final entry in kModerationReasonTitleVariants.entries) {
    if (entry.value.contains(normalized)) {
      return entry.key;
    }
  }

  return 'other';
}
