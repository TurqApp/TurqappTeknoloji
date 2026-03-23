part of 'social_media_links.dart';

class _SocialMediaLinksState extends State<SocialMediaLinks> {
  late final SocialMediaController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = SocialMediaController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SocialMediaController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SocialMediaController.maybeFind(), controller)) {
      Get.delete<SocialMediaController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(
              () => BackButtons(
                text: 'social_links.title'
                    .trParams({'count': '${controller.list.length}'}),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: Colors.black,
                color: Colors.white,
                onRefresh: () async {
                  await controller.getData(
                    silent: true,
                    forceRefresh: true,
                  );
                },
                child: Obx(
                  () => ReorderableBuilder(
                    children: controller.list
                        .asMap()
                        .entries
                        .map(
                          (entry) => KeyedSubtree(
                            key: ValueKey(entry.value.docID),
                            child: _buildGridCard(
                              entry.value,
                              index: entry.key,
                            ),
                          ),
                        )
                        .toList(),
                    onReorder: (ReorderedListFunction reorderFn) async {
                      final oldList = controller.list.toList();
                      final newList =
                          reorderFn(oldList).cast<SocialMediaModel>();

                      controller.list.value = newList;
                      await controller.updateAllSira();
                    },
                    builder: (children) {
                      if (controller.isLoading.value &&
                          controller.list.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        );
                      }
                      return GridView(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        children: [
                          ...children,
                          _buildAddButton(),
                        ],
                      );
                    },
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
