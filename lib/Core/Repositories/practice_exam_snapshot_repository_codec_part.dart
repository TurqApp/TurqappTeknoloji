part of 'practice_exam_snapshot_repository.dart';

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
          timeStamp: item['timeStamp'] is num
              ? item['timeStamp'] as num
              : num.tryParse((item['timeStamp'] ?? '0').toString()) ?? 0,
          sinavAciklama: (item['sinavAciklama'] ?? '').toString(),
          sinavAdi: (item['sinavAdi'] ?? '').toString(),
          kpssSecilenLisans: (item['kpssSecilenLisans'] ?? '').toString(),
          dersler: (item['dersler'] is List)
              ? (item['dersler'] as List)
                  .map((value) => value.toString())
                  .toList(growable: false)
              : const <String>[],
          taslak: item['taslak'] == true,
          public: item['public'] != false,
          userID: (item['userID'] ?? '').toString(),
          soruSayilari: (item['soruSayilari'] is List)
              ? (item['soruSayilari'] as List)
                  .map((value) => value.toString())
                  .toList(growable: false)
              : const <String>[],
          bitis: item['bitis'] is num
              ? item['bitis'] as num
              : num.tryParse((item['bitis'] ?? '0').toString()) ?? 0,
          bitisDk: item['bitisDk'] is num
              ? item['bitisDk'] as num
              : num.tryParse((item['bitisDk'] ?? '0').toString()) ?? 0,
          participantCount: item['participantCount'] is num
              ? item['participantCount'] as num
              : num.tryParse((item['participantCount'] ?? '0').toString()) ?? 0,
          shortId: (item['shortId'] ?? '').toString(),
          shortUrl: (item['shortUrl'] ?? '').toString(),
        );
      })
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false);
}
