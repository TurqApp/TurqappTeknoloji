class DersVeSonuclar {
  String ders;
  int dogru;
  int yanlis;
  int bos;

  DersVeSonuclar({
    required this.ders,
    required this.dogru,
    required this.yanlis,
    required this.bos,
  });
}

class DersVeSonuclarDB {
  String ders;
  num dogru;
  num yanlis;
  num bos;
  num net;

  DersVeSonuclarDB({
    required this.ders, //alsoDocID
    required this.dogru,
    required this.yanlis,
    required this.bos,
    required this.net,
  });
}