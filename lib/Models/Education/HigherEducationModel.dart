class HigherEducationModel {
  final int id;
  final String tip;
  final String sub;
  final String il;
  final String universite;
  final String fakulte;
  final String bolum;

  HigherEducationModel({
    required this.id,
    required this.tip,
    required this.sub,
    required this.il,
    required this.universite,
    required this.fakulte,
    required this.bolum,
  });

  factory HigherEducationModel.fromJson(Map<String, dynamic> json) {
    return HigherEducationModel(
      id: json['id'] ?? 0,
      tip: json['tip'] ?? '',
      sub: json['sub'] ?? '',
      il: json['il'] ?? '',
      universite: json['universite'] ?? '',
      fakulte: json['fakulte'] ?? '',
      bolum: json['bolum'] ?? '',
    );
  }
}
