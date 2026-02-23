import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/external.dart';
import 'cikmis_sorular_cover_model.dart';

class CikmisSorularPreview extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String yil;
  final String baslik2;
  final String baslik3;

  const CikmisSorularPreview({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
    required this.baslik2,
    required this.baslik3,
  });

  @override
  State<CikmisSorularPreview> createState() => _CikmisSorularPreviewState();
}

class _CikmisSorularPreviewState extends State<CikmisSorularPreview> {
  List<CikmisSorularinModeli> list = [];
  List<String> selectedAnswers = [];
  List<String> dogruCevaplarList = [];
  List<String> dersler = [];
  String? selectedSubject;
  String docIDCopy = "";
  late Timer _timer;
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  bool showAlert = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int hours, int minutes, int seconds) {
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds >= 60) {
          _seconds = 0;
          _minutes++;
          if (_minutes >= 60) {
            _minutes = 0;
            _hours++;
          }
        }
      });
    });
  }

  void _fetchData() {
    FirebaseFirestore.instance.collection("CikmisSorular").get().then((
      QuerySnapshot snapshot,
    ) {
      for (var doc in snapshot.docs) {
        String anaBaslik = doc.get("anaBaslik");
        String sinavTuru = doc.get("sinavTuru");
        String baslik2 = doc.get("baslik2");
        String baslik3 = doc.get("baslik3");
        String yil = doc.get("yil");

        if (anaBaslik == widget.anaBaslik &&
            sinavTuru == widget.sinavTuru &&
            baslik3 == widget.baslik3 &&
            baslik2 == widget.baslik2 &&
            yil == widget.yil) {
          _getData(doc.id);
        }
      }
    });
  }

  void _getData(String docID) {
    FirebaseFirestore.instance
        .collection("CikmisSorular")
        .doc(docID)
        .collection("Sorular")
        .get()
        .then((QuerySnapshot snapshot) {
      for (var doc in snapshot.docs) {
        var question = CikmisSorularinModeli(
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
            dogruCevaplarList.add(question.dogruCevap);
            selectedAnswers.add("");

            if (!dersler.contains(question.ders)) {
              dersler.add(question.ders);
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          docIDCopy = docID;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BackButtons(text: "Sorular"),
                    Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Text(
                        _formatTime(_hours, _minutes, _seconds),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var entry in dersler.asMap().entries)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          selectedSubject =
                                              selectedSubject == entry.value
                                                  ? null
                                                  : entry.value;
                                        });
                                        _scrollController.jumpTo(0);
                                      }
                                    },
                                    child: Container(
                                      height: 50,
                                      alignment: Alignment.centerLeft,
                                      color: tumderslerColors[entry.key],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.value, // Display the index and the subject name
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontFamily: "MontserratBold",
                                              ),
                                            ),
                                            Icon(
                                              selectedSubject == entry.value
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (selectedSubject == entry.value)
                                    for (var questionEntry in list
                                        .asMap()
                                        .entries
                                        .where(
                                          (e) => e.value.ders == entry.value,
                                        ))
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withValues(alpha: 
                                                0.5,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "${questionEntry.value.soruNo}. Soru", // Sorunun index değeri
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 20,
                                                                  fontFamily:
                                                                      "MontserratBold",
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 10),
                                                          CachedNetworkImage(
                                                            imageUrl:
                                                                questionEntry
                                                                    .value.soru,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                color: Colors.pinkAccent
                                                    .withValues(alpha: 0.5),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 15,
                                                    vertical: 10,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        widget.anaBaslik ==
                                                                "LGS"
                                                            ? MainAxisAlignment
                                                                .spaceAround
                                                            : MainAxisAlignment
                                                                .spaceBetween,
                                                    children:
                                                        (widget.anaBaslik ==
                                                                    "LGS"
                                                                ? [
                                                                    'A',
                                                                    'B',
                                                                    'C',
                                                                    'D',
                                                                  ]
                                                                : [
                                                                    'A',
                                                                    'B',
                                                                    'C',
                                                                    'D',
                                                                    'E',
                                                                  ])
                                                            .map((option) {
                                                      final isSelected =
                                                          selectedAnswers[
                                                                  questionEntry
                                                                      .key] ==
                                                              option;
                                                      return GestureDetector(
                                                        onTap: () {
                                                          if (isSelected) {
                                                            if (mounted) {
                                                              setState(() {
                                                                selectedAnswers[
                                                                    questionEntry
                                                                        .key] = "";
                                                              });
                                                            }
                                                          } else {
                                                            if (mounted) {
                                                              setState(() {
                                                                selectedAnswers[
                                                                    questionEntry
                                                                        .key] = option;
                                                              });
                                                            }
                                                          }
                                                        },
                                                        child: Container(
                                                          width: 45,
                                                          height: 45,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isSelected
                                                                ? Colors.black
                                                                : Colors
                                                                    .grey[100],
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            option,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            SizedBox(height: 60),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                FirebaseFirestore.instance
                    .collection("CikmisSorularGecmisi")
                    .add({
                  "cevaplar": selectedAnswers,
                  "dogruCevaplar": dogruCevaplarList,
                  "timeStamp": DateTime.now().millisecondsSinceEpoch,
                  "anaBaslik": widget.anaBaslik,
                  "sinavTuru": widget.sinavTuru,
                  "yil": widget.yil,
                  "baslik2": widget.baslik2,
                  "baslik3": widget.baslik3,
                  "cikmisSoruID": docIDCopy,
                  "userID": FirebaseAuth.instance.currentUser!.uid,
                });

                if (mounted) {
                  setState(() {
                    showAlert = true;
                  });
                }
              },
              child: Container(
                margin: EdgeInsets.all(15),
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Sınavı Bitir",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
            if (showAlert)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(18),
                        topLeft: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Testi Tamamladın!",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Test sonuçlarına çıkmış sorular ekranındaki sonuçlarım ekranında bakabilirsin.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                              SizedBox(height: 15),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Soru Çözmeye Devam Et",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
