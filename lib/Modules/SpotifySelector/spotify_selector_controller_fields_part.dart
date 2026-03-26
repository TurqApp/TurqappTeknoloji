part of 'spotify_selector_controller.dart';

class _SpotifySelectorControllerState {
  final RxList<MusicModel> library = <MusicModel>[].obs;
  final RxSet<String> savedTrackIds = <String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString currentPlayingUrl = ''.obs;
  final RxInt selectedTab = 0.obs;
  final RxString query = ''.obs;
  final RxInt visibleCount = 20.obs;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AudioPlayer audioPlayer = AudioPlayer();
}

extension SpotifySelectorControllerFieldsPart on SpotifySelectorController {
  RxList<MusicModel> get library => _state.library;
  RxSet<String> get savedTrackIds => _state.savedTrackIds;
  RxBool get isLoading => _state.isLoading;
  RxString get currentPlayingUrl => _state.currentPlayingUrl;
  RxInt get selectedTab => _state.selectedTab;
  RxString get query => _state.query;
  RxInt get visibleCount => _state.visibleCount;
  TextEditingController get searchController => _state.searchController;
  ScrollController get scrollController => _state.scrollController;
  AudioPlayer get _audioPlayer => _state.audioPlayer;
}
