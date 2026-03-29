part of 'practice_exam_snapshot_repository.dart';

num _asPracticeExamNum(Object? value) {
  if (value is num) return value;
  return num.tryParse((value ?? '0').toString()) ?? 0;
}

bool _asPracticeExamBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  final raw = (value ?? '').toString().trim().toLowerCase();
  if (raw == 'true' || raw == '1') return true;
  if (raw == 'false' || raw == '0') return false;
  return fallback;
}

List<String> _asPracticeExamStringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

Map<String, dynamic> _encodePracticeExamSnapshotItems(List<SinavModel> items) {
  return <String, dynamic>{
    'items': items
        .map(
          (item) => <String, dynamic>{
            'docID': item.docID,
            'cover': item.cover,
            'sinavTuru': item.sinavTuru,
            'timeStamp': item.timeStamp,
            'sinavAciklama': item.sinavAciklama,
            'sinavAdi': item.sinavAdi,
            'kpssSecilenLisans': item.kpssSecilenLisans,
            'dersler': item.dersler,
            'taslak': item.taslak,
            'public': item.public,
            'userID': item.userID,
            'soruSayilari': item.soruSayilari,
            'bitis': item.bitis,
            'bitisDk': item.bitisDk,
            'participantCount': item.participantCount,
            'shortId': item.shortId,
            'shortUrl': item.shortUrl,
          },
        )
        .toList(growable: false),
  };
}

List<SinavModel> _decodePracticeExamSnapshotItems(Map<String, dynamic> json) {
  final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
  return rawItems
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
        return SinavModel(
          docID: (item['docID'] ?? '').toString(),
          cover: (item['cover'] ?? '').toString(),
          sinavTuru: (item['sinavTuru'] ?? '').toString(),
          timeStamp: _asPracticeExamNum(item['timeStamp']),
          sinavAciklama: (item['sinavAciklama'] ?? '').toString(),
          sinavAdi: (item['sinavAdi'] ?? '').toString(),
          kpssSecilenLisans: (item['kpssSecilenLisans'] ?? '').toString(),
          dersler: _asPracticeExamStringList(item['dersler']),
          taslak: _asPracticeExamBool(item['taslak'], fallback: false),
          public: _asPracticeExamBool(item['public'], fallback: true),
          userID: (item['userID'] ?? '').toString(),
          soruSayilari: _asPracticeExamStringList(item['soruSayilari']),
          bitis: _asPracticeExamNum(item['bitis']),
          bitisDk: _asPracticeExamNum(item['bitisDk']),
          participantCount: _asPracticeExamNum(item['participantCount']),
          shortId: (item['shortId'] ?? '').toString(),
          shortUrl: (item['shortUrl'] ?? '').toString(),
        );
      })
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false);
}
