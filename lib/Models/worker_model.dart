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

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
        case 'evet':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'hayir':
        case 'hayır':
          return false;
      }
    }
    return fallback;
  }

  static num _asNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  WorkerModel({
    required this.userID,
    required List<String> calismaTuru,
    required this.call,
    required List<String> city,
    required this.info,
    required this.meslek,
    required this.timeStamp,
  })  : calismaTuru = _cloneStringList(calismaTuru),
        city = _cloneStringList(city);

  factory WorkerModel.fromMap(String id, Map<String, dynamic> data) {
    return WorkerModel(
      userID: id,
      calismaTuru: _asStringList(data["calismaTuru"]),
      call: _asBool(data["call"]),
      city: _asStringList(data["city"]),
      info: _asString(data["info"]),
      meslek: _asString(data["meslek"]),
      timeStamp: _asNum(data["timeStamp"]),
    );
  }
}
