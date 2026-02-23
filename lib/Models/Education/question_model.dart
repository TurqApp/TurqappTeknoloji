import 'package:turqappv2/Utils/error_messages.dart';

class QuestionModel {
  final String? docID;
  final String ders;
  final String dogruCevap;
  final int id;
  final String konu;
  final String soru;
  final List<String> yanitlayanlar;

  QuestionModel({
    required this.docID,
    required this.ders,
    required this.dogruCevap,
    required this.id,
    required this.konu,
    required this.soru,
    required this.yanitlayanlar,
  });

  QuestionModel copyWith({
    String? docID,
    String? ders,
    String? dogruCevap,
    int? id,
    String? konu,
    String? soru,
    List<String>? yanitlayanlar,
  }) {
    return QuestionModel(
      docID: docID ?? this.docID,
      ders: ders ?? this.ders,
      dogruCevap: dogruCevap ?? this.dogruCevap,
      id: id ?? this.id,
      konu: konu ?? this.konu,
      soru: soru ?? this.soru,
      yanitlayanlar: yanitlayanlar ?? this.yanitlayanlar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docID': docID,
      'ders': ders,
      'dogruCevap': dogruCevap,
      'id': id,
      'konu': konu,
      'soru': soru,
      'yanitlayanlar': yanitlayanlar,
    };
  }

  String? validate() {
    if (soru.isEmpty) return ErrorMessages.emptyQuestionImage;
    if (dogruCevap.isEmpty) return ErrorMessages.emptyCorrectAnswer;
    return null;
  }
}
