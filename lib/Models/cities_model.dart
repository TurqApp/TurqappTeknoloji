class CitiesModel {
  final String il;
  final String ilce;

  CitiesModel({required this.il, required this.ilce});

  factory CitiesModel.fromJson(Map<String, dynamic> json) =>
      CitiesModel(il: json['il'], ilce: json['ilce']);

  Map<String, dynamic> toJson() => {'il': il, 'ilce': ilce};
}
