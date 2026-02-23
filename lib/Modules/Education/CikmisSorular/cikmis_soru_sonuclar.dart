import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_sonuc_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSoruSonuclar extends StatefulWidget {
  const CikmisSoruSonuclar({super.key});

  @override
  State<CikmisSoruSonuclar> createState() => _CikmisSoruSonuclarState();
}

class _CikmisSoruSonuclarState extends State<CikmisSoruSonuclar> {
  List<CikmisSoruSonucModel> list = [];
  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    FirebaseFirestore.instance
        .collection("CikmisSorularGecmisi")
        .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((QuerySnapshot snap) {
      List<CikmisSoruSonucModel> tempList = [];

      for (var doc in snap.docs) {
        String anaBaslik = doc.get("anaBaslik");
        String sinavTuru = doc.get("sinavTuru");
        String yil = doc.get("yil");
        String baslik2 = doc.get("baslik2");
        String baslik3 = doc.get("baslik3");
        String userID = doc.get("userID");
        List<String> cevaplar = List.from(doc.get("cevaplar"));
        List<String> dogruCevaplar = List.from(doc.get("dogruCevaplar"));
        num timeStamp = doc.get("timeStamp");
        String cikmisSoruID = doc.get("cikmisSoruID");

        tempList.add(
          CikmisSoruSonucModel(
            anaBaslik: anaBaslik,
            sinavTuru: sinavTuru,
            yil: yil,
            baslik2: baslik2,
            baslik3: baslik3,
            userID: userID,
            cevaplar: cevaplar,
            timeStamp: timeStamp,
            cikmisSoruID: cikmisSoruID,
            dogruCevaplar: dogruCevaplar,
            docID: doc.id,
          ),
        );
      }

      if (mounted) {
        setState(() {
          tempList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
          list = tempList;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Sonuçlarım"),
            if (list.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 10 : 0),
                      child: Column(
                        children: [
                          CikmisSorularSonucContent(model: list[index]),
                          8.ph,
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Infomessage(infoMessage: "Her hangi bir sonuç yok"),
          ],
        ),
      ),
    );
  }
}
