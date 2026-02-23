class KonuModel {
  final String sinavTuru;
  final String ders;
  final String konu;

  KonuModel({required this.sinavTuru, required this.ders, required this.konu});

  factory KonuModel.fromJson(Map<String, dynamic> json) {
    return KonuModel(
      sinavTuru: json['sinav_turu'],
      ders: json['ders'],
      konu: json['konu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'sinav_turu': sinavTuru, 'ders': ders, 'konu': konu};
  }
}
