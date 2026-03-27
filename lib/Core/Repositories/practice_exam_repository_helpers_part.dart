part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryHelpersPart on PracticeExamRepository {
  SinavModel _fromDoc(String docId, Map<String, dynamic> data) {
    return SinavModel(
      docID: docId,
      cover: (data['cover'] ?? '').toString(),
      sinavTuru: (data['sinavTuru'] ?? '').toString(),
      timeStamp: data['timeStamp'] is num
          ? data['timeStamp'] as num
          : num.tryParse((data['timeStamp'] ?? '0').toString()) ?? 0,
      sinavAciklama: (data['sinavAciklama'] ?? '').toString(),
      sinavAdi: (data['sinavAdi'] ?? '').toString(),
      kpssSecilenLisans: (data['kpssSecilenLisans'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((e) => e.toString()).toList()
          : <String>[],
      taslak: data['taslak'] == true,
      public: data['public'] != false,
      userID: (data['userID'] ?? '').toString(),
      soruSayilari: (data['soruSayilari'] is List)
          ? (data['soruSayilari'] as List).map((e) => e.toString()).toList()
          : <String>[],
      bitis: data['bitis'] is num
          ? data['bitis'] as num
          : num.tryParse((data['bitis'] ?? '0').toString()) ?? 0,
      bitisDk: data['bitisDk'] is num
          ? data['bitisDk'] as num
          : num.tryParse((data['bitisDk'] ?? '0').toString()) ?? 0,
      participantCount: data['participantCount'] is num
          ? data['participantCount'] as num
          : num.tryParse((data['participantCount'] ?? '0').toString()) ?? 0,
      shortId: (data['shortId'] ?? '').toString(),
      shortUrl: (data['shortUrl'] ?? '').toString(),
    );
  }

  List<List<String>> _chunkIds(List<String> ids, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      chunks.add(ids.sublist(i, end));
    }
    return chunks;
  }

  SoruModel? _questionFromMap(Map<String, dynamic> raw) {
    final docId = (raw['id'] ?? '').toString();
    final resolvedDocId = (raw['_docId'] ?? docId).toString();
    if (resolvedDocId.isEmpty) return null;
    final numericId = raw['id'] is num
        ? raw['id'] as num
        : num.tryParse((raw['questionId'] ?? '0').toString()) ?? 0;
    return SoruModel(
      id: numericId.toInt(),
      soru: (raw['soru'] ?? '').toString(),
      ders: (raw['ders'] ?? '').toString(),
      konu: (raw['konu'] ?? '').toString(),
      dogruCevap: (raw['dogruCevap'] ?? '').toString(),
      docID: resolvedDocId,
    );
  }
}
