import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';

class CikmisSoruSonucPreview extends StatefulWidget {
  final CikmisSoruSonucModel model;
  final String title;

  const CikmisSoruSonucPreview(
      {super.key, required this.model, required this.title});
  @override
  State<CikmisSoruSonucPreview> createState() => _CikmisSoruSonucPreviewState();
}

class _CikmisSoruSonucPreviewState extends State<CikmisSoruSonucPreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "${widget.title} Sonuçlarım"),
            Expanded(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _summaryItem("Doğru", widget.model.dogruSayisi.toString()),
                            _summaryItem("Yanlış", widget.model.yanlisSayisi.toString()),
                            _summaryItem("Boş", widget.model.bosSayisi.toString()),
                            _summaryItem("Net", widget.model.net.toStringAsFixed(2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.model.anaBaslik.isNotEmpty)
                        Text(
                          widget.model.anaBaslik,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.model.soruSayisi} soru cozuldu. Sonuc local olarak tutuluyor; bu ekranda sadece net ozeti gosteriliyor.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _summaryItem(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontFamily: "MontserratBold",
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.black54,
          fontSize: 13,
          fontFamily: "MontserratMedium",
        ),
      ),
    ],
  );
}
