import 'package:flutter/material.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_soru_sonuc_preview.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSorularSonucContent extends StatefulWidget {
  final CikmisSoruSonucModel model;

  const CikmisSorularSonucContent({super.key, required this.model});

  @override
  State<CikmisSorularSonucContent> createState() =>
      _CikmisSorularSonucContentState();
}

class _CikmisSorularSonucContentState extends State<CikmisSorularSonucContent> {
  int toplamSoru = 0;
  int dogruSayisi = 0;
  int bosSayisi = 0;
  int yanlisSayisi = 0;

  String _denemeLabelFromYear(String year) {
    final parsedYear = int.tryParse(year);
    if (parsedYear == null) return year;
    final denemeNumber = (2025 - parsedYear).clamp(1, 999);
    return "Deneme $denemeNumber";
  }

  String _resultTitle() {
    final denemeLabel = _denemeLabelFromYear(widget.model.yil);
    if (widget.model.anaBaslik == "KPSS") {
      final prefix = widget.model.baslik3.contains("Lisans")
          ? widget.model.baslik2
          : widget.model.baslik3.replaceAll("ö", "Ö");
      return "$prefix $denemeLabel";
    }
    return "${widget.model.sinavTuru} $denemeLabel";
  }

  @override
  void initState() {
    toplamSoru = widget.model.dogruCevaplar.length;
    for (int i = 0; i < widget.model.dogruCevaplar.length; i++) {
      if (i < widget.model.cevaplar.length) {
        if (widget.model.cevaplar[i] == "") {
          bosSayisi++;
        } else if (widget.model.cevaplar[i] == widget.model.dogruCevaplar[i]) {
          dogruSayisi++;
        } else {
          yanlisSayisi++;
        }
      } else {
        bosSayisi++;
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CikmisSoruSonucPreview(
              model: widget.model,
              title: _resultTitle(),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _resultTitle(),
                            style: TextStyles.bold18Black,
                          ),
                        ),
                        Text(
                          timeAgo(widget.model.timeStamp),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                    4.ph,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "$toplamSoru Soru",
                            style: TextStyle(
                              color: Colors.indigo,
                              fontSize: 16,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              4.pw,
                              Text(
                                dogruSayisi.toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        8.pw,
                        SizedBox(
                          width: 50,
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              4.pw,
                              Text(
                                yanlisSayisi.toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        8.pw,
                        SizedBox(
                          width: 50,
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              4.pw,
                              Text(
                                bosSayisi.toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
