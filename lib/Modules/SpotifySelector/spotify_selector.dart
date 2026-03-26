import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector_controller.dart';

part 'spotify_selector_list_part.dart';
part 'spotify_selector_shell_part.dart';
part 'spotify_selector_shell_content_part.dart';

class SpotifySelector extends StatefulWidget {
  const SpotifySelector({super.key});

  @override
  State<SpotifySelector> createState() => _SpotifySelectorState();
}

class _SpotifySelectorState extends State<SpotifySelector> {
  late final SpotifySelectorController controller;
  late final String _controllerTag;

  static const List<String> _tabs = <String>[
    'spotify.tab.for_you',
    'spotify.tab.popular',
    'spotify.tab.all',
    'common.saved',
  ];

  @override
  void initState() {
    super.initState();
    _controllerTag = 'spotify_selector_${identityHashCode(this)}';
    controller = SpotifySelectorController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    final existing = SpotifySelectorController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<SpotifySelectorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchResetOnPageReturnScope(
        onReset: () {
          controller.searchController.clear();
        },
        child: _buildPage(context),
      );
}
