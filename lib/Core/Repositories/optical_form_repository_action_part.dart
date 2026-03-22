part of 'optical_form_repository.dart';

extension OpticalFormRepositoryActionPart on OpticalFormRepository {
  Future<void> initializeUserAnswers(
    String formId,
    String userId,
    int questionCount,
  ) async {
    final answers = List<String>.filled(questionCount, '');
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
    }, SetOptions(merge: true));
    await _storePrimitive('answers:$formId:$userId', answers);
  }

  Future<void> saveUserAnswers(
    String formId,
    String userId, {
    required List<String> answers,
    required String ogrenciNo,
    required String fullName,
  }) async {
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .update({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
      'ogrenciNo': ogrenciNo,
      'fullName': fullName,
    });
    await _storePrimitive('answers:$formId:$userId', answers);
  }

  Future<void> deleteForm(String formId) async {
    await _firestore.collection('optikForm').doc(formId).delete();
    _memory.remove('doc:$formId');
    _memory.remove('count:$formId');
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('${OpticalFormRepository._prefsPrefix}:doc:$formId');
    await _prefs?.remove(
      '${OpticalFormRepository._prefsPrefix}:count:$formId',
    );
  }
}
