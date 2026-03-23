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
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openSession(context, sessions[index]),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: _buildYearCard(index),
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

  Widget _buildYearCard(int index) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan,
                Colors.black.withValues(alpha: 0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 110;
              return Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _localizedExamType(widget.sinavTuru),
                              textScaler: TextScaler.noScaling,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _denemeLabel(sessions[index].sira),
                          textScaler: TextScaler.noScaling,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ),
                    if (sessions[index].yil.isNotEmpty) ...[
                      SizedBox(height: compact ? 2 : 4),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            sessions[index].yil,
                            textScaler: TextScaler.noScaling,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
    );
  }
}
