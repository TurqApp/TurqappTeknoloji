import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';

import '../CikmisSorular/cikmis_sorular_cover_model.dart';

class CikmisSoruSonucPreview extends StatefulWidget {
  final CikmisSoruSonucModel model;
  final String title;

  const CikmisSoruSonucPreview({super.key, required this.model, required this.title});
  @override
  State<CikmisSoruSonucPreview> createState() => _CikmisSoruSonucPreviewState();
}

class _CikmisSoruSonucPreviewState extends State<CikmisSoruSonucPreview> {
  List<CikmisSorularinModeli> list = []; //icerisinde dogruCevap == String
  List<String> cevaplar = [];
  String? selectedSubject;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getData(widget.model.cikmisSoruID);
    cevaplar = widget.model.cevaplar;
  }

  void _getData(String docID) {
    _loadQuestions(docID).then((questionDocs) {
      for (var doc in questionDocs) {
        final question = CikmisSorularinModeli(
          ders: doc.get("ders"),
          dogruCevap: doc.get("dogruCevap"),
          soru: doc.get("soru"),
          kacCevap: doc.get("kacCevap"),
          docID: doc.id,
          soruNo: doc.get("soruNo"),
        );

        if (mounted) {
          setState(() {
            list.add(question);
            if (!dersler.contains(question.ders)) {
              dersler.add(question.ders);
            }
          });
        }
      }
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadQuestions(
    String docID,
  ) async {
    final baseDoc = FirebaseFirestore.instance.collection("questions").doc(docID);

    final questionsSnap = await baseDoc.collection("questions").get();
    if (questionsSnap.docs.isNotEmpty) {
      return questionsSnap.docs;
    }

    final sorularSnap = await baseDoc.collection("Sorular").get();
    return sorularSnap.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "${widget.title} Sonuçlarım"),
            Divider(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final soru = list[index];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${soru.soruNo}. Soru", // Sorunun index değeri
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              Text(
                                soru.ders, // Dersin adı
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CachedNetworkImage(imageUrl: soru.soru),
                        ),
                        SizedBox(height: 10),
                        Container(
                          color: Colors.pinkAccent.withValues(alpha: 0.5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: widget.model.anaBaslik == "LGS"
                                  ? MainAxisAlignment.spaceAround
                                  : MainAxisAlignment.spaceBetween,
                              children: [
                                for (var secim
                                    in (widget.model.anaBaslik == "LGS"
                                            ? ['A', 'B', 'C', 'D']
                                            : ['A', 'B', 'C', 'D', 'E'])
                                        .asMap()
                                        .entries)
                                  GestureDetector(
                                    onTap: () {
                                      print(cevaplar[index]);
                                      print(secim.value);
                                    },
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        // Boş cevap durumunda
                                        color: (cevaplar[index] == "")
                                            ? Colors.orange // Boş cevap
                                            : (secim.value == soru.dogruCevap
                                                ? Colors.green // Doğru cevap
                                                : (cevaplar[index] ==
                                                        secim.value
                                                    ? Colors.red // Yanlış cevap
                                                    : Colors
                                                        .white)), // Varsayılan
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black),
                                      ),
                                      child: Text(
                                        secim.value, // secim değeri
                                        style: TextStyle(
                                          color: (cevaplar[index] ==
                                                      secim.value &&
                                                  secim.value !=
                                                      soru.dogruCevap)
                                              ? Colors
                                                  .white // Yanlış cevapsa beyaz
                                              : (secim.value == soru.dogruCevap
                                                  ? Colors
                                                      .white // Doğru cevaptaysa beyaz
                                                  : Colors
                                                      .black), // Varsayılan durumda siyah
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
