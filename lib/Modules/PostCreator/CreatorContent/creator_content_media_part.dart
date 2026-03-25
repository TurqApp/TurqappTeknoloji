part of 'creator_content.dart';

const Map<String, String> _videoLookLabelKeys = <String, String>{
  'original': 'post_creator.look.original',
  'clear': 'post_creator.look.clear',
  'cinema': 'post_creator.look.cinema',
  'vibe': 'post_creator.look.vibe',
  'bright': 'post_creator.look.bright',
};

const Map<String, IconData> _videoLookIcons = <String, IconData>{
  'original': CupertinoIcons.circle,
  'clear': CupertinoIcons.sparkles,
  'cinema': CupertinoIcons.film,
  'vibe': CupertinoIcons.sun_max,
  'bright': CupertinoIcons.sun_max_fill,
};

extension CreatorContentMediaPart on CreatorContent {
  Widget _buildMediaLookPreview(
    String preset,
    Widget child, {
    bool applyMatrix = true,
  }) {
    if (preset == 'original') return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (applyMatrix)
          ColorFiltered(
            colorFilter: ColorFilter.matrix(_lookMatrix(preset)),
            child: child,
          )
        else
          child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _lookOverlayGradient(preset),
            ),
          ),
        ),
      ],
    );
  }

  List<double> _lookMatrix(String preset) {
    switch (preset) {
      case 'clear':
        return const <double>[
          1.06,
          0,
          0,
          0,
          8,
          0,
          1.06,
          0,
          0,
          8,
          0,
          0,
          1.08,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'cinema':
        return const <double>[
          1.10,
          0,
          0,
          0,
          -10,
          0,
          1.02,
          0,
          0,
          -14,
          0,
          0,
          0.92,
          0,
          -20,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'vibe':
        return const <double>[
          1.08,
          0,
          0,
          0,
          4,
          0,
          1.08,
          0,
          0,
          2,
          0,
          0,
          1.04,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'bright':
        return const <double>[
          1.18,
          0,
          0,
          0,
          22,
          0,
          1.16,
          0,
          0,
          24,
          0,
          0,
          1.24,
          0,
          32,
          0,
          0,
          0,
          1,
          0,
        ];
      default:
        return const <double>[
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
    }
  }

  Gradient _lookOverlayGradient(String preset) {
    switch (preset) {
      case 'clear':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.white.withValues(alpha: 0.06),
          ],
        );
      case 'cinema':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        );
      case 'vibe':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0x1AF97316),
            Color(0x00000000),
            Color(0x1406B6D4),
          ],
        );
      case 'bright':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.24),
            const Color(0x1200C2FF),
            Colors.white.withValues(alpha: 0.10),
          ],
        );
      default:
        return const LinearGradient(
          colors: <Color>[Colors.transparent, Colors.transparent],
        );
    }
  }
}
