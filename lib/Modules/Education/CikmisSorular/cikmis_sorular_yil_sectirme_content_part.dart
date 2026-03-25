part of 'cikmis_sorular_yil_sectirme.dart';

extension CikmisSorularYilSectirmeContentPart
    on _CikmisSorularYilSectirmeState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(
              text: 'past_questions.tests_by_type'
                  .trParams({'type': _localizedExamType(widget.sinavTuru)}),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: yillar.length,
                        itemBuilder: (context, index) {
                          final yil = yillar[index];
                          return GestureDetector(
                            onTap: () => _openYear(context, yil),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: _buildYearCard(yil),
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

  Widget _buildYearCard(String yil) {
    final label = _denemeLabelForYear(yil);
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(label.trim());
    final title = match == null ? label : match.group(1)!.trim();
    final number = match == null ? '' : match.group(2)!.trim();
    return Column(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan,
                  Colors.black.withValues(alpha: 0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textScaler: TextScaler.noScaling,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: "MontserratBold",
                  ),
                ),
                if (number.isNotEmpty)
                  Text(
                    number,
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: "MontserratBold",
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
