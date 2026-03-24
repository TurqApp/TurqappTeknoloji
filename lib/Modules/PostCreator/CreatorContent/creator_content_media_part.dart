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

class _LookPalette {
  final List<Color> idleShell;
  final List<Color> activeShell;
  final List<Color> preview;
  final Color borderSoft;
  final Color borderStrong;
  final Color glow;
  final Color text;

  const _LookPalette({
    required this.idleShell,
    required this.activeShell,
    required this.preview,
    required this.borderSoft,
    required this.borderStrong,
    required this.glow,
    required this.text,
  });
}

extension CreatorContentMediaPart on CreatorContent {
  _LookPalette _lookPalette(String preset) {
    switch (preset) {
      case 'clear':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFFFFF), Color(0xFFF3FAFF)],
          activeShell: <Color>[Color(0xFFF7FBFF), Color(0xFFEAF5FF)],
          preview: <Color>[Color(0xFFFFFFFF), Color(0xFFD8EEFF)],
          borderSoft: Color(0xFFE0EDF7),
          borderStrong: Color(0xFFB8D7F2),
          glow: Color(0x1A52A7E8),
          text: Color(0xFF1B425E),
        );
      case 'cinema':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFF26262E), Color(0xFF1A1A21)],
          activeShell: <Color>[Color(0xFF1B1B22), Color(0xFF2C2C35)],
          preview: <Color>[Color(0xFF403B2F), Color(0xFF13151C)],
          borderSoft: Color(0xFF3C3D49),
          borderStrong: Color(0xFF4A4A58),
          glow: Color(0x22000000),
          text: Colors.white,
        );
      case 'vibe':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFF7F1), Color(0xFFFFECD9)],
          activeShell: <Color>[Color(0xFFFFF3E7), Color(0xFFFFE2CF)],
          preview: <Color>[Color(0xFFFF8F5A), Color(0xFFFFD76A)],
          borderSoft: Color(0xFFFFD4B4),
          borderStrong: Color(0xFFFFC59A),
          glow: Color(0x22FF8744),
          text: Color(0xFF6E3316),
        );
      case 'bright':
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFF8FEFF), Color(0xFFEEFAFF)],
          activeShell: <Color>[Color(0xFFF4FEFF), Color(0xFFE1F6FF)],
          preview: <Color>[Color(0xFFFFFFFF), Color(0xFFC5F0FF)],
          borderSoft: Color(0xFFCDEEFF),
          borderStrong: Color(0xFF8EDBFF),
          glow: Color(0x2431C8FF),
          text: Color(0xFF0E4660),
        );
      default:
        return const _LookPalette(
          idleShell: <Color>[Color(0xFFFFFFFF), Color(0xFFF8F8F8)],
          activeShell: <Color>[Color(0xFFF3F5F7), Color(0xFFECEFF3)],
          preview: <Color>[Color(0xFFF8F8F8), Color(0xFFE9ECF1)],
          borderSoft: Color(0xFFE8EAED),
          borderStrong: Color(0xFFE2E5E9),
          glow: Color(0x12000000),
          text: Color(0xFF25282C),
        );
    }
  }

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
