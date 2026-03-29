class WorkerModel {
  String userID;
  List<String> calismaTuru;
  bool call;
  List<String> city;
  String info;
  String meslek;
  num timeStamp;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  WorkerModel({
    required this.userID,
    required List<String> calismaTuru,
    required this.call,
    required List<String> city,
    required this.info,
    required this.meslek,
    required this.timeStamp,
  }) : calismaTuru = _cloneStringList(calismaTuru),
       city = _cloneStringList(city);

  factory WorkerModel.fromMap(String id, Map<String, dynamic> data) {
    return WorkerModel(
      userID: id,
      calismaTuru: List<String>.from(data["calismaTuru"] ?? []),
      call: data["call"] ?? false,
      city: List<String>.from(data["city"] ?? []),
      info: data["info"] ?? "",
      meslek: data["meslek"] ?? "",
      timeStamp: data["timeStamp"] ?? 0,
    );
  }
}
