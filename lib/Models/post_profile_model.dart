class PostProfileModel {
  String docID;
  List<String> img;
  String video;
  String thumbnasilOfVideo;
  String metin;
  bool gonderiGizlendi;
  bool sikayetEdildi;
  String userID;
  num izBirakYayinTarihi;
  num timeStamp;
  List<String>? goruntuleme;

  PostProfileModel({
    required this.docID,
    required this.img,
    required this.video,
    required this.thumbnasilOfVideo,
    required this.metin,
    required this.sikayetEdildi,
    required this.gonderiGizlendi,
    required this.userID,
    required this.izBirakYayinTarihi,
    required this.timeStamp,
    this.goruntuleme,
  });
}
