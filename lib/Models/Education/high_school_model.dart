class HighSchoolModel {
  final String tip;
  final String sub;
  final String il;
  final String ilce;
  final String adi;
  final String url;
  final String tel;
  final String adres;

  HighSchoolModel({
    required this.tip,
    required this.sub,
    required this.il,
    required this.ilce,
    required this.adi,
    required this.url,
    required this.tel,
    required this.adres,
  });

  factory HighSchoolModel.fromJson(Map<String, dynamic> json) {
    return HighSchoolModel(
      tip: (json['tip'] ?? '').toString(),
      sub: (json['sub'] ?? '').toString(),
      il: (json['il'] ?? '').toString(),
      ilce: (json['ilce'] ?? '').toString(),
      adi: (json['adi'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      tel: (json['tel'] ?? '').toString(),
      adres: (json['adres'] ?? '').toString(),
    );
  }
}
