class CitiesModel {
  final String il;
  final String ilce;

  CitiesModel({required this.il, required this.ilce});

  factory CitiesModel.fromJson(Map<String, dynamic> json) {
    return CitiesModel(il: json['il'], ilce: json['ilce']);
  }

  Map<String, dynamic> toJson() {
    return {'il': il, 'ilce': ilce};
  }
}
