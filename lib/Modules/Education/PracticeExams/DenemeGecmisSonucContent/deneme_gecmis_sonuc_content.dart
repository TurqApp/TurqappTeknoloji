import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSonuclariPreview/sinav_sonuclari_preview.dart';

part 'deneme_gecmis_sonuc_content_body_part.dart';
part 'deneme_gecmis_sonuc_content_actions_part.dart';

class DenemeGecmisSonucContent extends StatelessWidget {
  final SinavModel model;
  final int index;

  const DenemeGecmisSonucContent({
    super.key,
    required this.index,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _openResultsPreview,
          child: _buildResultCard(),
        ),
        Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ],
    );
  }
}
