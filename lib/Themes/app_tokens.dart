import 'package:flutter/material.dart';

/// TurqApp Design System Tokens
///
/// Tüm magic number'lar bu dosyadan okunmalı.
/// Widget içinde hardcoded 16, 12, 8 gibi değerler yerine token kullan.
///
/// ```dart
/// Padding(
///   padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
///   child: Text('Merhaba', style: AppTypography.bodyMedium),
/// )
/// ```

// ─────────────────────────────────────────────────────────────────
// 🎨 COLOR TOKENS
// ─────────────────────────────────────────────────────────────────

class AppColorTokens {
  // Brand
  static const Color primary = Color(0xFF4F718E);
  static const Color primaryDark = Color(0xFF183351);
  static const Color primaryLight = Color(0xFF7A9CB8);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceSecondary = Color(0xFFF2F2F7);
  static const Color surfaceSecondaryDark = Color(0xFF2C2C2E);

  // Text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  static const Color textInverted = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFFE5E5EA);
  static const Color borderDark = Color(0xFF38383A);

  // Overlay
  static const Color overlayLight = Color(0x1A000000); // 10%
  static const Color overlayMedium = Color(0x4D000000); // 30%
  static const Color overlayHeavy = Color(0x99000000); // 60%

  // Video player
  static const Color videoBackground = Color(0xFF000000);
  static const Color progressBar = Color(0xFFFFFFFF);
  static const Color progressBarBackground = Color(0x4DFFFFFF);
}

// ─────────────────────────────────────────────────────────────────
// 📏 SPACING TOKENS (4px grid)
// ─────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // Named aliases
  static const double screenPadding = lg; // Ekran kenar boşluğu
  static const double cardPadding = md; // Kart iç boşluk
  static const double itemSpacing = sm; // Liste item arası
  static const double sectionSpacing = xxl; // Bölüm arası
  static const double avatarGap = sm; // Avatar → isim arası
}

// ─────────────────────────────────────────────────────────────────
// 🔤 TYPOGRAPHY TOKENS
// ─────────────────────────────────────────────────────────────────

class AppTypography {
  // Headline
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'MontserratBold',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'MontserratBold',
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'MontserratBold',
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'MontserratBold',
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'MontserratMedium',
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'MontserratMedium',
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'MontserratMedium',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColorTokens.textSecondary,
  );

  // Post
  static const TextStyle postName = TextStyle(
    fontFamily: 'MontserratBold',
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle postHandle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle postMeta = TextStyle(
    fontFamily: 'MontserratMedium',
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle postAttribution = TextStyle(
    fontFamily: 'MontserratMedium',
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle postCaption = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Backward-compatible aliases for feed surfaces using post typography.
  static const TextStyle feedName = postName;
  static const TextStyle feedHandle = postHandle;
  static const TextStyle feedMeta = postMeta;
  static const TextStyle feedCaption = postCaption;
}

// ─────────────────────────────────────────────────────────────────
// 🔘 BORDER RADIUS TOKENS
// ─────────────────────────────────────────────────────────────────

class AppRadius {
  static const double none = 0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0; // Pill shape

  // Named aliases
  static const double button = md;
  static const double card = lg;
  static const double bottomSheet = xl;
  static const double avatar = full;
  static const double chip = full;
  static const double inputField = sm;
}

// ─────────────────────────────────────────────────────────────────
// ⏱️ ANIMATION DURATION TOKENS
// ─────────────────────────────────────────────────────────────────

class AppDuration {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Video/media
  static const Duration videoFadeIn = Duration(milliseconds: 200);
  static const Duration thumbnailFadeOut = Duration(milliseconds: 300);
}

// ─────────────────────────────────────────────────────────────────
// 📱 LAYOUT TOKENS
// ─────────────────────────────────────────────────────────────────

class AppLayout {
  static const double navBarHeight = 56.0;
  static const double tabBarHeight = 48.0;
  static const double appBarHeight = 56.0;
  static const double bottomSheetHandleHeight = 4.0;
  static const double bottomSheetHandleWidth = 36.0;

  // Avatar sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarStory = 56.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Button heights
  static const double buttonSm = 36.0;
  static const double buttonMd = 44.0;
  static const double buttonLg = 52.0;

  // Feed
  static const double feedItemMaxWidth = 600.0; // Tablet'te merkezleme
}

// ─────────────────────────────────────────────────────────────────
// 🌑 ELEVATION / SHADOW TOKENS
// ─────────────────────────────────────────────────────────────────

class AppElevation {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
