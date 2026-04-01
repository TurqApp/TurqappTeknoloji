part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryHelpersPart on PracticeExamRepository {
  num _practiceExamAsNum(Object? value, {num fallback = 0}) {
    if (value is num) return value;
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) return fallback;
    return num.tryParse(normalized) ?? fallback;
  }

  bool _practiceExamAsBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return fallback;
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }

  SinavModel _fromDoc(String docId, Map<String, dynamic> data) {
    return SinavModel(
      docID: docId,
      cover: (data['cover'] ?? '').toString(),
      sinavTuru: (data['sinavTuru'] ?? '').toString(),
      timeStamp: _practiceExamAsNum(data['timeStamp']),
      sinavAciklama: (data['sinavAciklama'] ?? '').toString(),
      sinavAdi: (data['sinavAdi'] ?? '').toString(),
      kpssSecilenLisans: (data['kpssSecilenLisans'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((e) => e.toString()).toList()
          : <String>[],
      taslak: _practiceExamAsBool(data['taslak'], fallback: false),
      public: _practiceExamAsBool(data['public'], fallback: true),
      userID: (data['userID'] ?? '').toString(),
      soruSayilari: (data['soruSayilari'] is List)
          ? (data['soruSayilari'] as List).map((e) => e.toString()).toList()
          : <String>[],
      bitis: _practiceExamAsNum(data['bitis']),
      bitisDk: _practiceExamAsNum(data['bitisDk']),
      participantCount: _practiceExamAsNum(data['participantCount']),
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
        : _practiceExamAsNum(raw['questionId']);
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
