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

part 'cikmis_sorular_preview_data_part.dart';
part 'cikmis_sorular_preview_content_part.dart';

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

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
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
