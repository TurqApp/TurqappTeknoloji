class DormitoryModel {
  final String tip;
  final String sub;
  final String ilAdi;
  final String adi;

  DormitoryModel({
    required this.tip,
    required this.sub,
    required this.ilAdi,
    required this.adi,
  });

  factory DormitoryModel.fromJson(Map<String, dynamic> json) {
    return DormitoryModel(
      tip: json['tip'],
      sub: json['sub'],
      ilAdi: json['il_adi'],
      adi: json['adi'],
    );
  }
}
