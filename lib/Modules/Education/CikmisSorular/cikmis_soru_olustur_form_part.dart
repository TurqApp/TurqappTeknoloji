part of 'cikmis_soru_olustur.dart';

extension _CikmisSoruOlusturFormPart on _CikmisSoruOlusturState {
  static final List<Color> _examColors = [
    Colors.black,
    Colors.green[500]!,
    Colors.purple[500]!,
    Colors.red[500]!,
    Colors.orange[500]!,
    Colors.teal[500]!,
  ];

  Widget _buildExamTypesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "education.exam_types".tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sinavTurleriList.length,
            itemBuilder: (context, index) {
              final examType = sinavTurleriList[index];
              return _buildExamTypeChip(examType, index);
            },
          ),
        ),
        if (sinavTuru == _CikmisSoruOlusturState._sinavTuruKpss) ...[
          const SizedBox(height: 10),
          _buildKpssLevelSelector(),
        ],
        const SizedBox(height: 20),
        _buildQuestionCountSection(),
      ],
    );
  }

  Widget _buildExamTypeChip(String examType, int index) {
    final isSelected = sinavTuru == examType;
    return GestureDetector(
      onTap: () => _selectExamType(examType),
      child: Padding(
        padding: EdgeInsets.only(right: 12, left: index == 0 ? 20 : 0),
        child: Container(
          height: 60,
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? _examColors[index % _examColors.length]
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(50)),
          ),
          child: Text(
            examType,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 15,
              fontFamily: isSelected ? "MontserratBold" : "MontserratMedium",
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpssLevelSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: kpssOgretimTipleri.length,
          itemBuilder: (context, index) {
            final level = kpssOgretimTipleri[index];
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _buildKpssLevelChip(level),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpssLevelChip(String level) {
    final isSelected = kpssSecilenLisans == level;
    return GestureDetector(
      onTap: () => _selectKpssLevel(level),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.indigo : Colors.grey.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            level,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountSection() {
    if (dersler.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        for (int i = 0; i < dersler.length; i++)
          _buildQuestionCountRow(
            subject: dersler[i],
            controller: soruSayisiTextFields[i],
          ),
      ],
    );
  }

  Widget _buildQuestionCountRow({
    required String subject,
    required TextEditingController controller,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                maxLines: 1,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "education.question_count_hint".tr,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: "MontserratMedium",
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                  height: 1.8,
                ),
                onChanged: (_) => _updateViewState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectExamType(String examType) {
    _updateViewState(() {
      sinavTuru = examType;

      if (sinavTuru == _CikmisSoruOlusturState._sinavTuruLgs) {
        dersler = lgsDersler;
      } else if (sinavTuru == _CikmisSoruOlusturState._sinavTuruTyt) {
        dersler = tytDersler;
      } else if (sinavTuru == _CikmisSoruOlusturState._sinavTuruAyt) {
        dersler = aytDersler;
      } else if (sinavTuru == _CikmisSoruOlusturState._sinavTuruKpss) {
        kpssSecilenLisans = _CikmisSoruOlusturState._kpssLisansOrtaogretim;
        dersler = kpssDerslerOrtaVeOnLisans;
      } else if (sinavTuru == _CikmisSoruOlusturState._sinavTuruAles ||
          sinavTuru == _CikmisSoruOlusturState._sinavTuruDgs) {
        dersler = alesVeDgsDersler;
      } else if (sinavTuru == _CikmisSoruOlusturState._sinavTuruYds) {
        dersler = ydsDersler;
      } else {
        dersler = ydsDersler;
      }

      _recreateQuestionControllers();
    });
  }

  void _selectKpssLevel(String level) {
    _updateViewState(() {
      kpssSecilenLisans = level;

      if (_isKpssCommonLevel(kpssSecilenLisans)) {
        dersler = kpssDerslerOrtaVeOnLisans;
      } else if (kpssSecilenLisans ==
          _CikmisSoruOlusturState._kpssLisansEgitimBirimleri) {
        dersler = kpssDerslerEgitimbirimleri;
      } else if (kpssSecilenLisans ==
          _CikmisSoruOlusturState._kpssLisansAGrubu1) {
        dersler = kpssDerslerAgrubu1;
      } else if (kpssSecilenLisans ==
          _CikmisSoruOlusturState._kpssLisansAGrubu2) {
        dersler = kpssDerslerAgrubu2;
      }

      _recreateQuestionControllers(initialText: "1");
    });
  }
}
