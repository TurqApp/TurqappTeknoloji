// 📁 lib/Modules/Agenda/Common/AgendaSpacing.dart
// 📐 Professional responsive spacing system for agenda posts
// Eliminates magic numbers and enables dynamic, device-aware layouts

import 'package:flutter/material.dart';

/// Centralized spacing system for post layouts
/// All spacing calculations happen here for consistency
class AgendaSpacing {
  const AgendaSpacing._();

  // ==================== BASE UNITS ====================
  /// Base spacing unit (8dp grid system)
  static const double _unit = 8.0;

  /// Avatar size (consistent across app)
  static const double avatarRadius = 19.0; // 38px diameter
  static const double avatarDiameter = avatarRadius * 2;

  // ==================== MODERN STYLE ====================

  /// Modern style: Content offset from left (avatar + gap)
  /// Formula: avatarDiameter + (gap * 2)
  /// Result: 38 + 7 = 45px (but calculated, not hardcoded!)
  static double get modernContentLeftMargin => avatarDiameter + (_unit * 0.875);

  /// Modern style: Text padding from left edge
  static EdgeInsets get modernTextPadding => EdgeInsets.only(
    left: modernContentLeftMargin,
    top: _unit,
  );

  /// Modern style: Media (image/video) padding
  static EdgeInsets get modernMediaPadding => EdgeInsets.only(
    top: _unit,
    left: modernContentLeftMargin,
    right: _unit,
  );

  /// Modern style: Location pin padding
  static EdgeInsets get modernLocationPadding => EdgeInsets.only(
    top: _unit * 0.875,
    left: modernContentLeftMargin - _unit * 0.625, // Slight left of content
  );

  /// Modern style: Post container padding
  static const EdgeInsets modernContainerPadding = EdgeInsets.symmetric(
    horizontal: _unit * 0.625, // 5px
  );

  // ==================== CLASSIC STYLE ====================

  /// Classic style: Full width, minimal padding
  static const EdgeInsets classicContainerPadding = EdgeInsets.zero;

  /// Classic style: Header padding (horizontal)
  static const EdgeInsets classicHeaderPadding = EdgeInsets.symmetric(
    horizontal: _unit, // 8px
  );

  /// Classic style: Header white variant padding
  static const EdgeInsets classicHeaderWhitePadding = EdgeInsets.symmetric(
    horizontal: _unit, // 8px
    vertical: _unit, // 8px
  );

  /// Classic style: Text-only post padding
  static EdgeInsets get classicTextPadding => const EdgeInsets.symmetric(
    horizontal: _unit * 1.875, // 15px
  );

  /// Classic style: Quotation mark positioning
  static const double quotationMarkLeftOffset = _unit * 1.875; // 15px
  static const double quotationMarkRightOffset = _unit * 1.875; // 15px

  /// Classic style: Header subtitle (includes location)
  static const EdgeInsets classicHeaderSubtitlePadding = EdgeInsets.only(
    top: _unit * 0.5, // 4px
  );

  /// Classic style: Reshare/Quote padding
  static const EdgeInsets classicReshareQuotePadding = EdgeInsets.only(
    top: _unit * 0.5, // 4px
    left: _unit, // 8px
    right: _unit, // 8px
  );

  /// Classic style: Action buttons row padding
  static const EdgeInsets classicActionsPadding = EdgeInsets.only(
    top: _unit * 0.5, // 4px
  );

  /// Classic style: Nickname text padding
  static const EdgeInsets classicNicknamePadding = EdgeInsets.only(
    top: _unit, // 8px
  );

  /// Classic style: Video footer caption padding
  static const EdgeInsets classicVideoCaptionPadding = EdgeInsets.only(
    left: _unit, // 8px
    bottom: _unit, // 8px
  );

  /// Classic style: Page indicator margin
  static const EdgeInsets classicPageIndicatorMargin = EdgeInsets.symmetric(
    horizontal: _unit * 0.375, // 3px
  );

  /// Classic style: Badge/Rozet padding
  static const EdgeInsets classicBadgePadding = EdgeInsets.only(
    left: _unit * 0.5, // 4px
    right: _unit * 1.5, // 12px
  );

  /// Classic style: Follow button left padding
  static const EdgeInsets classicFollowButtonPadding = EdgeInsets.only(
    left: _unit * 1.25, // 10px
  );

  // ==================== SHARED SPACING ====================

  /// Gap between avatar and text/content
  static const double avatarToContentGap = _unit * 0.75; // 6px

  /// Gap between header and content
  static const double headerToContentGap = _unit; // 8px

  /// Gap between content and actions
  static const double contentToActionsGap = _unit; // 8px

  /// Padding around action buttons
  static const EdgeInsets actionButtonPadding = EdgeInsets.symmetric(
    horizontal: _unit,
    vertical: _unit * 0.5,
  );

  /// Border radius for media (images/videos)
  static const double mediaBorderRadius = _unit * 1.5; // 12px

  /// Spacing between multiple images in grid
  static const double imageGridSpacing = _unit * 0.5; // 4px

  /// Padding for reshare attribution label
  static const EdgeInsets reshareAttributionPadding = EdgeInsets.only(
    top: _unit * 0.5,
    left: _unit,
    right: _unit,
  );

  // ==================== RESPONSIVE HELPERS ====================

  /// Get spacing based on screen width (for future responsive design)
  static double responsiveUnit(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return _unit * 0.875; // Compact phones
    if (width > 600) return _unit * 1.125; // Tablets
    return _unit; // Normal phones
  }

  /// Calculate left margin dynamically based on context
  static double getContentLeftMargin(BuildContext context, bool isModern) {
    if (!isModern) return 0;

    final unit = responsiveUnit(context);
    return avatarDiameter + (unit * 0.875);
  }

  /// Get media aspect ratio constraints
  static double constrainAspectRatio(double original) {
    // Prevent too tall/wide images
    if (original < 0.5) return 0.5;   // Max height
    if (original > 2.0) return 2.0;   // Max width
    return original;
  }

  // ==================== ANIMATION DURATIONS ====================

  /// Standard animation duration for state changes
  static const Duration standardAnimation = Duration(milliseconds: 300);

  /// Fast animation for micro-interactions
  static const Duration fastAnimation = Duration(milliseconds: 150);

  /// Slow animation for major transitions
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // ==================== TYPOGRAPHY SPACING ====================

  /// Line height for post text
  static const double textLineHeight = 1.4;

  /// Maximum lines before "read more" in modern view
  static const int modernTextMaxLines = 7;

  /// Maximum lines before expand in classic view
  static const int classicTextMaxLines = 7;

  // ==================== INTERACTION AREAS ====================

  /// Minimum touch target size (Material Design)
  static const double minTouchTarget = 48.0;

  /// Icon button size
  static const double iconButtonSize = 40.0;

  /// Small icon size (for actions)
  static const double smallIconSize = 20.0;

  /// Medium icon size
  static const double mediumIconSize = 24.0;

  // ==================== ELEVATION & SHADOWS ====================

  /// Card elevation
  static const double cardElevation = 0.0; // Flat design

  /// Subtle shadow for depth
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: _unit,
      offset: Offset(0, _unit * 0.25),
    ),
  ];
}

/// Extension methods for convenient spacing access
extension AgendaSpacingExtensions on num {
  /// Convert number to spacing unit (e.g., 2.spacing = 16px)
  double get spacing => this * AgendaSpacing._unit;

  /// Vertical spacing widget
  SizedBox get verticalSpace => SizedBox(height: spacing);

  /// Horizontal spacing widget
  SizedBox get horizontalSpace => SizedBox(width: spacing);
}
