import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/KonuModel.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SoruModel.dart';

class SoruContent extends StatefulWidget {
  final SoruModel model;
  final String sinavTuru;
  final String mainID;
  final int index;
  final String ders;
  SoruContent({
    super.key,
    required this.model,
    required this.sinavTuru,
    required this.mainID,
    required this.index,
    required this.ders,
  });

  @override
  State<SoruContent> createState() => _SoruContentState();
}

class _SoruContentState extends State<SoruContent> {
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  String dogruCevap = "";
  String konu = "";
  List<KonuModel> konuList = [];
  List<KonuModel> filteredKonuList = [];

  @override
  void initState() {
    super.initState();
    dogruCevap = widget.model.dogruCevap;
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        yukle(selectedImage!, widget.mainID);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> yukle(File imageFile, String mainID) async {
    try {
      // Dosya adını al
      String fileName = basename(imageFile.path);

      // Firebase Storage referansını oluştur
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(
        'SinavSorulari/$mainID/$fileName',
      );

      // Dosyayı yükle
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // İndirme URL'sini al
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      FirebaseFirestore.instance
          .collection("Sinavlar")
          .doc(widget.mainID)
          .collection("Sorular")
          .doc(widget.model.docID)
          .set({
            "id": widget.model.id,
            "soru": downloadUrl,
            "ders": widget.ders,
            "konu": konu,
            "dogruCevap": dogruCevap,
            "yanitlayanlar": [],
          }, SetOptions(merge: true));
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }

  void fastSetData() {
    FirebaseFirestore.instance
        .collection("Sinavlar")
        .doc(widget.mainID)
        .collection("Sorular")
        .doc(widget.model.docID)
        .set({
          "id": widget.model.id,
          "ders": widget.ders,
          "konu": konu,
          "dogruCevap": dogruCevap,
          "yanitlayanlar": [],
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, top: widget.index == 0 ? 20 : 0),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            selectedImage != null || widget.model.soru != ""
                ? GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 7),
                          widget.model.soru != ""
                              ? Image.network(widget.model.soru)
                              : Column(
                                children: [
                                  SizedBox(height: 15),
                                  Image.file(selectedImage!),
                                ],
                              ),
                        ],
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/education/createsoru.webp",
                        height: 150,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              height: 35,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  "Galeriden Seç",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: _pickImageFromCamera,
                            child: Container(
                              height: 35,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  "Kameradan Çek",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            if (selectedImage != null || widget.model.soru != "")
              Container(
                color: Colors.pinkAccent.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        widget.sinavTuru == "LGS"
                            ? MainAxisAlignment.spaceAround
                            : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var item
                          in widget.sinavTuru == "LGS"
                              ? ['A', 'B', 'C', 'D']
                              : ['A', 'B', 'C', 'D', 'E'])
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                dogruCevap = item;
                                fastSetData();
                              });
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      dogruCevap == item
                                          ? Colors.green
                                          : Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  border: Border.all(
                                    color:
                                        dogruCevap == item
                                            ? Colors.green
                                            : Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color:
                                        dogruCevap == item
                                            ? Colors.white
                                            : Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
