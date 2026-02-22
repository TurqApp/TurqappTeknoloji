class WorkerModel {
  String userID;
  List<String> calismaTuru;
  bool call;
  List<String> city;
  String info;
  String meslek;
  num timeStamp;

  WorkerModel({
    required this.userID,
    required this.calismaTuru,
    required this.call,
    required this.city,
    required this.info,
    required this.meslek,
    required this.timeStamp,
  });

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
