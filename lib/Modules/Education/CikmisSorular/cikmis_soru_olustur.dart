import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';

part 'cikmis_soru_olustur_form_part.dart';
part 'cikmis_soru_olustur_shell_part.dart';

class CikmisSoruOlustur extends StatefulWidget {
  const CikmisSoruOlustur({super.key});

  @override
  State<CikmisSoruOlustur> createState() => _CikmisSoruOlusturState();
}

class _CikmisSoruOlusturState extends State<CikmisSoruOlustur> {
  static const _sinavTuruLgs = 'LGS';
  static const _sinavTuruTyt = 'TYT';
  static const _sinavTuruAyt = 'AYT';
  static const _sinavTuruKpss = 'KPSS';
  static const _sinavTuruAles = 'ALES';
  static const _sinavTuruDgs = 'DGS';
  static const _sinavTuruYds = 'YDS';
  static const _kpssLisansOrtaogretim = 'Ortaöğretim';
  static const _kpssLisansOnLisans = 'Ön Lisans';
  static const _kpssLisansLisans = 'Lisans';
  static const _kpssLisansEgitimBirimleri = 'Eğitim Birimleri';
  static const _kpssLisansAGrubu1 = 'A Grubu 1';
  static const _kpssLisansAGrubu2 = 'A Grubu 2';

  List<String> dersler = [];
  String sinavTuru = _sinavTuruLgs;
  String kpssSecilenLisans = _kpssLisansOrtaogretim;
  List<TextEditingController> soruSayisiTextFields = [];

  bool _isKpssCommonLevel(String value) =>
      value == _kpssLisansOrtaogretim ||
      value == _kpssLisansOnLisans ||
      value == _kpssLisansLisans;

  @override
  void initState() {
    super.initState();
    dersler = lgsDersler;
    _recreateQuestionControllers(initialText: "40");
  }

  @override
  void dispose() {
    // Tüm controller'ları temizle
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    super.dispose();
  }

  void disposeTextEditingControllers() {
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
  }

  void _recreateQuestionControllers({String initialText = ""}) {
    disposeTextEditingControllers();
    soruSayisiTextFields = List.generate(
      dersler.length,
      (index) => TextEditingController(text: initialText),
    );
  }

  void _updateViewState(VoidCallback action) {
    if (!mounted) return;
    setState(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    _buildExamTypesSection(context),
                    const SizedBox(height: 20),
                    _buildStartBanner(),
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
