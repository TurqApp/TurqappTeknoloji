import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Services/current_user_service.dart';
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
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();
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

  int get _correctCount {
    var count = 0;
    for (var i = 0;
        i < selectedAnswers.length && i < dogruCevaplarList.length;
        i++) {
      final answer = selectedAnswers[i];
      if (answer.isNotEmpty && answer == dogruCevaplarList[i]) {
        count++;
      }
    }
    return count;
  }

  int get _wrongCount {
    var count = 0;
    for (var i = 0;
        i < selectedAnswers.length && i < dogruCevaplarList.length;
        i++) {
      final answer = selectedAnswers[i];
      if (answer.isNotEmpty && answer != dogruCevaplarList[i]) {
        count++;
      }
    }
    return count;
  }

  int get _emptyCount {
    return selectedAnswers.where((e) => e.isEmpty).length;
  }

  double get _netScore {
    return _correctCount - (_wrongCount * 0.25);
  }

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

  Future<void> _fetchData() async {
    final docId = await _repository.findQuestionDocId(
      anaBaslik: widget.anaBaslik,
      sinavTuru: widget.sinavTuru,
      yil: widget.yil,
      baslik2: widget.baslik2,
      baslik3: widget.baslik3,
    );
    if (docId != null && docId.isNotEmpty) {
      await _getData(docId);
    }
  }

  Future<void> _getData(String docID) async {
    final questions = await _repository.fetchQuestionItems(docID);
    if (!mounted) return;
    final localDersler = <String>[];
    final answers = <String>[];
    final selected = <String>[];
    for (final question in questions) {
      answers.add(question.dogruCevap);
      selected.add("");
      if (!localDersler.contains(question.ders)) {
        localDersler.add(question.ders);
      }
    }
    setState(() {
      list = questions;
      dogruCevaplarList = answers;
      selectedAnswers = selected;
      dersler = localDersler;
      docIDCopy = docID;
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
                    BackButtons(text: 'past_questions.questions_title'.tr),
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
                                              entry
                                                  .value, // Display the index and the subject name
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
                                    ...() {
                                      final subjectQuestions = list
                                          .asMap()
                                          .entries
                                          .where(
                                            (e) => e.value.ders == entry.value,
                                          )
                                          .toList(growable: false);
                                      final children = <Widget>[];
                                      for (var i = 0;
                                          i < subjectQuestions.length;
                                          i++) {
                                        final questionEntry =
                                            subjectQuestions[i];
                                        children.add(Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withValues(
                                                alpha: 0.5,
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
                                                                'tests.question_number'.trParams({
                                                                  'index':
                                                                      questionEntry
                                                                          .value
                                                                          .soruNo,
                                                                }),
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
                                                          width: 40,
                                                          height: 40,
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
                                      ));
                                        if ((i + 1) % 3 == 0) {
                                          children.add(
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              child: Center(
                                                child: AdmobKare(),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                      return children;
                                    }(),
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
                _repository.saveResult(
                  uid: CurrentUserService.instance.userId.isNotEmpty
                      ? CurrentUserService.instance.userId
                      : "local",
                  anaBaslik: widget.anaBaslik,
                  sinavTuru: widget.sinavTuru,
                  yil: widget.yil,
                  baslik2: widget.baslik2,
                  baslik3: widget.baslik3,
                  cikmisSoruID: docIDCopy,
                  soruSayisi: list.length,
                  dogruSayisi: _correctCount,
                  yanlisSayisi: _wrongCount,
                  bosSayisi: _emptyCount,
                  net: _netScore,
                );

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
                  'tests.finish_test'.tr,
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
                    height: (MediaQuery.of(context).size.height * 0.34)
                        .clamp(220.0, 260.0),
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
                                    'tests.completed_title'.tr,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.12),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _resultItem(
                                      'tests.correct'.tr,
                                      _correctCount.toString(),
                                    ),
                                    _resultItem(
                                      'tests.wrong'.tr,
                                      _wrongCount.toString(),
                                    ),
                                    _resultItem(
                                      'tests.blank'.tr,
                                      _emptyCount.toString(),
                                    ),
                                    _resultItem(
                                      'past_questions.net_label'.tr,
                                      _netScore.toStringAsFixed(2),
                                    ),
                                  ],
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
                                    'past_questions.continue_solving'.tr,
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

Widget _resultItem(String title, String value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: "MontserratBold",
        ),
      ),
      const SizedBox(height: 2),
      Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    ],
  );
}
