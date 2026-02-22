import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String docID;
  final num timeStamp;
  final String userID;
  final num lat;
  final num long;
  final String postType;
  final String postID;
  final List<String> imgs;
  final String video;
  final bool isRead;
  final List<String> kullanicilar;
  final List<String> begeniler;
  final String metin;
  final String sesliMesaj;
  final String kisiAdSoyad;
  final String kisiTelefon;

  MessageModel({
    required this.docID,
    required this.timeStamp,
    required this.userID,
    required this.lat,
    required this.long,
    required this.postType,
    required this.postID,
    required this.imgs,
    required this.video,
    required this.isRead,
    required this.kullanicilar,
    required this.metin,
    required this.sesliMesaj,
    required this.kisiAdSoyad,
    required this.kisiTelefon,
    required this.begeniler,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String docID) {
    return MessageModel(
      docID: docID,
      timeStamp: json['timeStamp'] ?? 0,
      userID: json['userID'] ?? '',
      lat: json['lat'] ?? 0,
      long: json['long'] ?? 0,
      postType: json['postType'] ?? '',
      postID: json['postID'] ?? '',
      imgs: List<String>.from(json['imgs'] ?? []),
      video: json['video'] ?? '',
      isRead: json['isRead'] ?? false,
      kullanicilar: List<String>.from(json['kullanicilar'] ?? []),
      begeniler: List<String>.from(json['begeniler'] ?? []),
      metin: json['metin'] ?? '',
      sesliMesaj: json['sesliMesaj'] ?? '',
      kisiAdSoyad: json['kisiAdSoyad'] ?? '',
      kisiTelefon: json['kisiTelefon'] ?? '',
    );
  }

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromJson(data, doc.id);
  }
}
