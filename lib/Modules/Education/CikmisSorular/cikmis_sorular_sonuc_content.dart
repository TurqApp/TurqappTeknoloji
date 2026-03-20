import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class CikmisSorularSonucContent extends StatefulWidget {
  final CikmisSoruSonucModel model;

  const CikmisSorularSonucContent({super.key, required this.model});

  @override
  State<CikmisSorularSonucContent> createState() =>
      _CikmisSorularSonucContentState();
}

class _CikmisSorularSonucContentState extends State<CikmisSorularSonucContent> {
  static const _kpss = 'KPSS';
  static const _undergraduate = 'Lisans';

  String _denemeLabelFromYear(String year) {
    final parsedYear = int.tryParse(year);
    if (parsedYear == null) return year;
    final denemeNumber = (2025 - parsedYear).clamp(1, 999);
    return 'past_questions.mock_label'
        .trParams({'index': denemeNumber.toString()});
  }

  String _resultTitle() {
    final denemeLabel = _denemeLabelFromYear(widget.model.yil);
    if (widget.model.anaBaslik == _kpss) {
      final prefix = widget.model.baslik3.contains(_undergraduate)
          ? widget.model.baslik2
          : widget.model.baslik3.replaceAll("ö", "Ö");
      return "$prefix $denemeLabel";
    }
    return "${widget.model.sinavTuru} $denemeLabel";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
            6.ph,
            Text(
              'past_questions.question_count'
                  .trParams({'count': widget.model.soruSayisi.toString()}),
              style: TextStyle(
                color: Colors.indigo,
                fontSize: 16,
                fontFamily: "MontserratBold",
              ),
            ),
            10.ph,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricChip(
                  'tests.correct'.tr,
                  widget.model.dogruSayisi.toString(),
                  Colors.green,
                ),
                _metricChip(
                  'tests.wrong'.tr,
                  widget.model.yanlisSayisi.toString(),
                  Colors.red,
                ),
                _metricChip(
                  'tests.blank'.tr,
                  widget.model.bosSayisi.toString(),
                  Colors.orangeAccent,
                ),
                _metricChip(
                  'past_questions.net_label'.tr,
                  widget.model.net.toStringAsFixed(2),
                  Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _metricChip(String label, String value, Color dotColor) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ),
      4.pw,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratBold",
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    ],
  );
}
