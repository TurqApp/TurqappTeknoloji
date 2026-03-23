import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';

import 'cikmis_sorular_preview.dart';

class CikmisSorularBaslik3Secimi extends StatefulWidget {
  final String anaBaslik;
  final String sinavTuru;
  final String yil;
  final String baslik2;
  final int? sira;

  const CikmisSorularBaslik3Secimi({
    super.key,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
    required this.baslik2,
    this.sira,
  });

  @override
  State<CikmisSorularBaslik3Secimi> createState() =>
      _CikmisSorularBaslik3SecimiState();
}

class _CikmisSorularBaslik3SecimiState
    extends State<CikmisSorularBaslik3Secimi> {
  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();
  List<String> basliklar = [];

  String _localizedExamType(String raw) {
    switch (raw) {
      case 'Ön Lisans':
        return 'past_questions.exam_type.associate'.tr;
      case 'Lisans':
        return 'past_questions.exam_type.undergraduate'.tr;
      default:
        return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _repository
        .distinctValues(
      where: (doc) =>
          (doc['anaBaslik'] ?? '').toString() == widget.anaBaslik &&
          (doc['sinavTuru'] ?? '').toString() == widget.sinavTuru &&
          (doc['yil'] ?? '').toString() == widget.yil &&
          (doc['baslik2'] ?? '').toString() == widget.baslik2 &&
          (widget.sira == null ||
              ((doc['sira'] as num?)?.toInt() ?? 0) == widget.sira),
      field: 'baslik3',
    )
        .then((items) {
      if (mounted) {
        setState(() {
          basliklar = items;
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
            Container(
              height: 70,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  AppBackButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppPageTitle(
                      'past_questions.sessions_by_year'
                          .trParams({'year': widget.yil}),
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // İç GridView'da kaydırma devre dışı
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Yan yana 2 eleman
                          crossAxisSpacing: 10.0, // Yatay boşluk
                          mainAxisSpacing: 10.0, // Dikey boşluk
                          childAspectRatio: 3 / 4, // En-boy oranı 3:4
                        ),
                        itemCount: basliklar.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CikmisSorularPreview(
                                    anaBaslik: widget.anaBaslik,
                                    sinavTuru: widget.sinavTuru,
                                    yil: widget.yil,
                                    baslik2: widget.baslik2,
                                    baslik3: basliklar[index],
                                    sira: widget.sira,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black, // Başlangıç rengi,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black45,
                                        Colors.black.withValues(
                                          alpha: 0.9,
                                        ), // Alt renk
                                      ],
                                      begin: Alignment
                                          .topCenter, // Gradyan başlangıç noktası (yukarı)
                                      end: Alignment
                                          .bottomCenter, // Gradyan bitiş noktası (aşağı)
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ), // Gölge rengi ve opaklık
                                        blurRadius: 6, // Gölge bulanıklık
                                        offset: Offset(
                                          0,
                                          0,
                                        ), // Gölgenin konumu (x,y)
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                basliklar[index],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        SizedBox(height: 4),
                                        Text(
                                          _localizedExamType(widget.sinavTuru),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 20,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
