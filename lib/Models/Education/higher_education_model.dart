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
      id: _asInt(json['id']),
      tip: (json['tip'] ?? '').toString(),
      sub: (json['sub'] ?? '').toString(),
      il: (json['il'] ?? '').toString(),
      universite: (json['universite'] ?? '').toString(),
      fakulte: (json['fakulte'] ?? '').toString(),
      bolum: (json['bolum'] ?? '').toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
