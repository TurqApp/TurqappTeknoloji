import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/NotificationService.dart';
import 'package:uuid/uuid.dart';

import '../../Core/BlockedTexts.dart';
import '../../Core/Services/OptimizedNSFWService.dart';
import '../../Models/MessageModel.dart';

class ChatController extends GetxController {
  String chatID;
  String userID;
  var nickname = "".obs;
  var pfImage = "".obs;
  var token = "".obs;
  var fullName = "".obs;
  var bio = "".obs;
  var selection = 0.obs;
  var textMesage = ''.obs;
  var uploadPercent = 0.0.obs;
  RxList<MessageModel> messages = <MessageModel>[].obs;
  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();
  FocusNode focus = FocusNode();
  var currentPage = 0.obs;
  final picker = ImagePicker();
  RxList<File> images = <File>[].obs;
  StreamSubscription? messageStream;
  var showScrollDownButton = false.obs;

  ChatController({required this.chatID, required this.userID});

  @override
  void onInit() {
    super.onInit();
    getUserData();
    getData();
    textEditingController.addListener(() {
      textMesage.value = textEditingController.text;
    });
    scrollController.addListener(() {
      showScrollDownButton.value = scrollController.offset > 500;
    });
  }

  @override
  void onClose() {
    messageStream?.cancel();
    super.onClose();
  }

  void getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .get();
    nickname.value = doc.get("nickname");
    pfImage.value = doc.get("pfImage");
    fullName.value = "${doc.get("firstName")} ${doc.get("lastName")}";
    bio.value = doc.get("bio");
    token.value = doc.get("token");
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void getData() {
    messageStream = FirebaseFirestore.instance
        .collection('Mesajlar')
        .doc(chatID)
        .collection('Chat')
        .orderBy("timeStamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.clear();
      for (var doc in snapshot.docs) {
        final kullanicilar = List.from(doc.get("kullanicilar"));

        if (kullanicilar.contains(FirebaseAuth.instance.currentUser!.uid)) {
          messages.add(MessageModel.fromJson(doc.data(), doc.id));
          if (doc.get("userID") != FirebaseAuth.instance.currentUser!.uid) {
            FirebaseFirestore.instance
                .collection('Mesajlar')
                .doc(chatID)
                .collection('Chat')
                .doc(doc.id)
                .update({"isRead": true});
          }
        }
      }
    });
  }

  Future<void> sendMessage({
    List<String>? imageUrls,
    LatLng? latLng,
    String? kisiAdSoyad,
    String? kisiTelefon,
    String? gif,
    String? postID,
    String? postType,
  }) async {
    print("🚀 sendMessage BAŞLADI");

    final text = textEditingController.text.trim();
    print("✏️ Mesaj text: '$text'");

    // 1. Küfür kontrolü
    if (text.isNotEmpty && kufurKontrolEt(text)) {
      print("⛔️ Küfür bulundu, return!");
      AppSnackbar(
        "Topluluk Kurallarına Aykırı",
        "Göndermeye çalıştığınız mesaj uygunsuz içerik içeriyor. Lütfen saygılı bir dil kullanın.",
        backgroundColor: Colors.red.withOpacity(0.7),
      );
      return;
    }
    print("✅ Küfür yok, devam!");

    // 2. Mesaj koşulları
    if (text.isNotEmpty ||
        (imageUrls?.isNotEmpty ?? false) ||
        latLng != null ||
        (kisiAdSoyad?.isNotEmpty ?? false) ||
        (postID?.isNotEmpty ?? false) ||
        (gif?.isNotEmpty ?? false)) {
      print("📨 Mesaj gönderme koşulları sağlandı");

      // Notif body
      String notifBody;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        notifBody = "${imageUrls.length} adet resim gönderdi";
      } else if (postID != null && postID.isNotEmpty) {
        notifBody = "Bir gönderi paylaştı";
      } else if (latLng != null) {
        notifBody = "Bir konum gönderdi";
      } else if (kisiAdSoyad != null && kisiAdSoyad.isNotEmpty) {
        notifBody = "Bir rehber bilgisi paylaştı";
      } else if (gif != null && gif.isNotEmpty) {
        notifBody = "Bir GIF gönderdi";
      } else {
        notifBody = text;
      }
      print("🔔 Notif body: $notifBody");

      final mesajData = {
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "userID": FirebaseAuth.instance.currentUser!.uid,
        "lat": latLng?.latitude.toDouble() ?? 0.0,
        "long": latLng?.longitude.toDouble() ?? 0.0,
        "postType": postType ?? "",
        "postID": postID ?? "",
        "imgs": gif != null ? [gif] : (imageUrls ?? []),
        "video": "",
        "isRead": false,
        "kullanicilar": [userID, FirebaseAuth.instance.currentUser!.uid],
        "metin": text,
        "sesliMesaj": "",
        "kisiAdSoyad": kisiAdSoyad ?? "",
        "kisiTelefon": kisiTelefon ?? "",
        "begeniler": [],
      };

      print("🗂 Mesaj data hazır, firestore'a ekleniyor...");

// Notif
      NotificationService.instance.sendNotification(
        token: token.value,
        title: nickname.value,
        body: notifBody,
        docID: chatID,
        type: "Chat",
      );
      print("🔔 Notification gönderildi");

      await FirebaseFirestore.instance
          .collection("Mesajlar")
          .doc(chatID)
          .collection("Chat")
          .add(mesajData);
      print("✅ Firestore'a mesaj eklendi");

// timestamp güncelleme
      try {
        await FirebaseFirestore.instance
            .collection("Mesajlar")
            .doc(chatID)
            .set({
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
          "deleted": [],
          "userID1": FirebaseAuth.instance.currentUser!.uid,
          "userID2": userID
        }, SetOptions(merge: true));
        print("🕒 chatID'nin timestamp'i güncellendi");
      } catch (e, s) {
        print("🔥 HATA: chatID'nin timestamp'i güncellenemedi: $e");
        print(s);
      }

// ...devamı aynı...

      print("🧹 TextEditingController temizleniyor...");
      textEditingController.clear();
      print("🎉 MESAJ TAMAMEN GÖNDERİLDİ ve TEMİZLENDİ!");
    } else {
      print("❗️Hiçbir mesaj gönderme koşulu sağlanmadı, mesaj gönderilmiyor.");
    }
  }

  Future<void> pickImage() async {
    final List<XFile> picked = await picker.pickMultiImage(limit: 10);
    if (picked.isEmpty) return;

    // 1) Seçilenleri File listesine dönüştür
    final files = picked.map((x) => File(x.path)).toList();

    // 2) NSFW tespiti (OptimizedNSFWService)
    for (final f in files) {
      final r = await OptimizedNSFWService.checkImage(f);
      if (r.isNSFW) {
        // Uygunsuz içerik varsa kullanıcıyı uyar, state'i güncelleme
        AppSnackbar(
          "Yükleme Başarısız!",
          "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
          backgroundColor: Colors.red.withOpacity(0.7),
        );
        return;
      }
    }

    // 3) Her şey temizse state'i set et
    images.value = files;
    selection.value = 1;
  }

  Future<void> pickCameraImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // NSFW tespiti (OptimizedNSFWService)
    final r = await OptimizedNSFWService.checkImage(file);
    if (r.isNSFW) {
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withOpacity(0.7),
      );
      return;
    }

    // Temizse ekle
    images.value = [file];
    selection.value = 1;
  }

  Future<void> uploadImageToStorage() async {
    uploadPercent.value = 1;
    final storage = FirebaseStorage.instance;
    final uuid = Uuid();

    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = uuid.v4(); // benzersiz isim

      final ref = storage.ref().child(
            'ChatAssets/$chatID/$fileName${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      final uploadTask = ref.putFile(image);

      // Yüklenme yüzdesi hesapla
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double percent =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Resim $i yükleniyor: %${percent.toStringAsFixed(2)}');
        uploadPercent.value = percent;
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
      print('Resim $i yüklendi: $downloadUrl');
    }

    print('Tüm URL’ler: $downloadUrls');

    uploadPercent.value = 0;
    selection.value = 0;

    sendMessage(imageUrls: downloadUrls);
  }

  Future<void> selectContact() async {
    if (!await FlutterContacts.requestPermission()) {
      print("Rehber izni verilmedi.");
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      sendMessage(
        kisiAdSoyad: contact.displayName,
        kisiTelefon: contact.phones.first.number,
      );
    } else {
      print("Kişi seçilmedi.");
    }
  }
}
