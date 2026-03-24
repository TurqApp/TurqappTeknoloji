import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Tests/TestEntry/test_entry_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'test_entry_shell_part.dart';

class TestEntry extends StatefulWidget {
  const TestEntry({super.key});

  @override
  State<TestEntry> createState() => _TestEntryState();
}

class _TestEntryState extends State<TestEntry> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final TestEntryController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'test_entry_${identityHashCode(this)}';
    _ownsController =
        TestEntryController.maybeFind(tag: _controllerTag) == null;
    controller = TestEntryController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController =
          TestEntryController.maybeFind(tag: _controllerTag);
      if (identical(registeredController, controller)) {
        Get.delete<TestEntryController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildResultCard() {
    final model = controller.model.value!;
    return SizedBox(
      height: 75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 75,
            width: 75,
            child: AspectRatio(
              aspectRatio: 1,
              child: model.img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: model.img,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CupertinoActivityIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.indigo,
                        strokeWidth: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tests.type_test'.trParams({
                    'type': controller.localizedTestType(model.testTuru),
                  }),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                Text(
                  model.aciklama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                Text(
                  controller.localizedLessons(model.dersler),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
