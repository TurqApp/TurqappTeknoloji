class MiddleSchoolModel {
  final String tip;
  final String sub;
  final String il;
  final String ilce;
  final String adi;
  final String url;
  final String tel;
  final String adres;

  MiddleSchoolModel({
    required this.tip,
    required this.sub,
    required this.il,
    required this.ilce,
    required this.adi,
    required this.url,
    required this.tel,
    required this.adres,
  });

  factory MiddleSchoolModel.fromJson(Map<String, dynamic> json) {
    return MiddleSchoolModel(
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

  Map<String, dynamic> toJson() {
    return {
      'tip': tip,
      'sub': sub,
      'il': il,
      'ilce': ilce,
      'adi': adi,
      'url': url,
      'tel': tel,
      'adres': adres,
    };
  }
}
