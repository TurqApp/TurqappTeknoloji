import 'package:cloud_functions/cloud_functions.dart';

enum EducationTypesenseEntity {
  scholarship,
  practiceExam,
  answerKey,
  tutoring,
  job,
  workout,
  pastQuestion,
}

extension _EntityName on EducationTypesenseEntity {
  String get apiLabel {
    switch (this) {
      case EducationTypesenseEntity.scholarship:
        return 'scholarship';
      case EducationTypesenseEntity.practiceExam:
        return 'practice_exam';
      case EducationTypesenseEntity.answerKey:
        return 'answer_key';
      case EducationTypesenseEntity.tutoring:
        return 'tutoring';
      case EducationTypesenseEntity.job:
        return 'job';
      case EducationTypesenseEntity.workout:
        return 'workout';
      case EducationTypesenseEntity.pastQuestion:
        return 'past_question';
    }
  }
}

class TypesenseEducationSearchService {
  TypesenseEducationSearchService._();

  static final TypesenseEducationSearchService instance =
      TypesenseEducationSearchService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<List<String>> searchDocIds({
    required EducationTypesenseEntity entity,
    required String query,
    int limit = 30,
    int page = 1,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return [];
    final callable = _functions.httpsCallable('f21_searchEducationCallable');
    final response = await callable.call(<String, dynamic>{
      'q': normalized,
      'entity': entity.apiLabel,
      'limit': limit,
      'page': page,
    });
    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = (data['hits'] as List<dynamic>?) ?? [];
    final ids = <String>[];
    for (final rawHit in hits) {
      final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
      if (hitMap == null) continue;

      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isNotEmpty) ids.add(docId);
    }
    return ids;
  }
}
