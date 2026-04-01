part of 'booklet_result_preview.dart';

extension _BookletResultPreviewContentPart on _BookletResultPreviewState {
  Widget _buildBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: widget.model.dogruCevaplar.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSummarySection();
                  }
                  return _buildAnswerRow(index - 1, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: const Row(
        children: [
          AppBackButton(icon: Icons.arrow_back),
          SizedBox(width: 8),
          Expanded(
            child: AppPageTitle(
              'tests.results_title',
              translate: true,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        Obx(
          () => controller.anaModel.value == null
              ? const Center(
                  child: CupertinoActivityIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: controller.anaModel.value!.cover,
                            fit: BoxFit.contain,
                            height: 50,
                            placeholder: (context, url) => const SizedBox(
                              height: 50,
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.anaModel.value!.baslik,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                Text(
                                  controller.anaModel.value!.yayinEvi,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                                Text(
                                  widget.model.baslik,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontSize: 15,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        SizedBox(
          height: 70,
          child: Row(
            children: [
              _buildStatBox(
                color: Colors.green,
                label: 'tests.correct'.tr,
                value: widget.model.dogru.toString(),
              ),
              _buildStatBox(
                color: Colors.red,
                label: 'tests.wrong'.tr,
                value: widget.model.yanlis.toString(),
              ),
              _buildStatBox(
                color: Colors.orange,
                label: 'tests.blank'.tr,
                value: widget.model.bos.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'MontserratBold',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
