// 📁 lib/Modules/Agenda/Common/post_content_style.dart
// 🎨 Professional style configuration for unified PostContent widget
// Eliminates code duplication between Classic and Modern views

import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Agenda/Common/agenda_spacing.dart';

/// Defines visual style AND behavior for post content rendering
/// This separates presentation AND behavioral concerns from business logic
///
/// **CRITICAL:** This is NOT just styling - it controls behavioral differences too!
class PostContentStyle {
  const PostContentStyle({
    required this.name,
    required this.useGridLayout,
    required this.showQuotationMarks,
    required this.showLocationInline,
    required this.enablePinchZoom,
    required this.useClickableText,
    required this.containerPadding,
    required this.actionButtonStyle,
    // BEHAVIORAL PARAMETERS (not just visual!)
    required this.enableBufferedAutoplay,
    required this.scrollFeedToTopOnReshare,
    required this.enableLegacyCommentSync,
    required this.useWhiteVideoHeader,
  });

  /// Style name for debugging
  final String name;

  // ==================== VISUAL PARAMETERS ====================

  /// Use grid layout for multiple images vs PageView with dots
  /// Modern: true (2x2 grid, 3-image layout, etc.)
  /// Classic: false (PageView with indicator dots)
  final bool useGridLayout;

  /// Show decorative quotation marks on text-only posts
  /// Modern: false (clean look)
  /// Classic: true (decorative " " marks)
  final bool showQuotationMarks;

  /// Show location inline in header subtitle vs separate row
  /// Modern: false (separate row with pin icon)
  /// Classic: true (subtitle in header)
  final bool showLocationInline;

  /// Enable pinch-to-zoom on images
  /// Modern: true (interactive experience)
  /// Classic: false (simple tap to preview)
  final bool enablePinchZoom;

  /// Use ClickableTextContent with hashtag/mention detection vs simple text
  /// Modern: true (interactive hashtags, mentions, URLs)
  /// Classic: false (NicknameWithTextLine widget)
  final bool useClickableText;

  /// Container padding (wraps entire post)
  final EdgeInsets containerPadding;

  /// Action button appearance
  final PostActionStyle actionButtonStyle;

  // ==================== BEHAVIORAL PARAMETERS ====================

  /// Wait for video buffer before autoplay (Modern) vs immediate play (Classic)
  /// Modern: true (waits for 10% buffer)
  /// Classic: false (plays immediately)
  ///
  /// **WHY THIS MATTERS:** Affects perceived performance and data usage
  /// - Buffered: Smoother playback, uses more data upfront
  /// - Immediate: Faster perceived start, may stutter
  final bool enableBufferedAutoplay;

  /// Scroll feed to top when resharing (Classic) vs stay in place (Modern)
  /// Modern: false (adds without scroll)
  /// Classic: true (scrolls to top with 800ms animation)
  ///
  /// **WHY THIS MATTERS:** UX decision about feed interruption
  final bool scrollFeedToTopOnReshare;

  /// Enable legacy "Yorumlar" collection fallback for old comments
  /// Modern: false (new schema only)
  /// Classic: true (backward compatibility)
  ///
  /// **WHY THIS MATTERS:** Data migration support
  final bool enableLegacyCommentSync;

  /// Use white header overlay for video (Classic) vs black header (Modern)
  /// Modern: false (always black header)
  /// Classic: true (white overlay on video)
  ///
  /// **WHY THIS MATTERS:** Visual consistency with video content
  final bool useWhiteVideoHeader;

  /// Modern style (Twitter/X-like with left margin alignment)
  /// - Content offset from avatar
  /// - Grid layouts for images
  /// - Interactive text elements
  /// - Pinch zoom enabled
  const PostContentStyle.modern()
      : name = 'modern',
        useGridLayout = true,
        showQuotationMarks = false,
        showLocationInline = false,
        enablePinchZoom = true,
        useClickableText = true,
        containerPadding = AgendaSpacing.modernContainerPadding,
        actionButtonStyle = const PostActionStyle.modern(),
        enableBufferedAutoplay = true,
        scrollFeedToTopOnReshare = false,
        enableLegacyCommentSync = false,
        useWhiteVideoHeader = false;

  /// Classic style (traditional full-width feed)
  /// - Full width content
  /// - PageView for images
  /// - Simple text display
  /// - Decorative elements (quotation marks)
  /// - Immediate video autoplay
  /// - Feed scroll to top on reshare
  /// - Legacy comment support
  const PostContentStyle.classic()
      : name = 'classic',
        useGridLayout = false,
        showQuotationMarks = true,
        showLocationInline = true,
        enablePinchZoom = false,
        useClickableText = false,
        containerPadding = AgendaSpacing.classicContainerPadding,
        actionButtonStyle = const PostActionStyle.classic(),
        enableBufferedAutoplay = false,
        scrollFeedToTopOnReshare = true,
        enableLegacyCommentSync = true,
        useWhiteVideoHeader = true;

  /// Get left margin for content (dynamically calculated)
  double getContentLeftMargin(BuildContext context) {
    if (name == 'modern') {
      return AgendaSpacing.getContentLeftMargin(context, true);
    }
    return 0;
  }

  /// Get text padding based on style
  EdgeInsets getTextPadding(BuildContext context) {
    if (name == 'modern') {
      return AgendaSpacing.modernTextPadding;
    }
    return AgendaSpacing.classicTextPadding;
  }

  /// Get media (image/video) padding
  EdgeInsets getMediaPadding(BuildContext context) {
    if (name == 'modern') {
      return AgendaSpacing.modernMediaPadding;
    }
    return EdgeInsets.zero;
  }

  /// Copy with overrides
  PostContentStyle copyWith({
    String? name,
    bool? useGridLayout,
    bool? showQuotationMarks,
    bool? showLocationInline,
    bool? enablePinchZoom,
    bool? useClickableText,
    EdgeInsets? containerPadding,
    PostActionStyle? actionButtonStyle,
    bool? enableBufferedAutoplay,
    bool? scrollFeedToTopOnReshare,
    bool? enableLegacyCommentSync,
    bool? useWhiteVideoHeader,
  }) {
    return PostContentStyle(
      name: name ?? this.name,
      useGridLayout: useGridLayout ?? this.useGridLayout,
      showQuotationMarks: showQuotationMarks ?? this.showQuotationMarks,
      showLocationInline: showLocationInline ?? this.showLocationInline,
      enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
      useClickableText: useClickableText ?? this.useClickableText,
      containerPadding: containerPadding ?? this.containerPadding,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      enableBufferedAutoplay:
          enableBufferedAutoplay ?? this.enableBufferedAutoplay,
      scrollFeedToTopOnReshare:
          scrollFeedToTopOnReshare ?? this.scrollFeedToTopOnReshare,
      enableLegacyCommentSync:
          enableLegacyCommentSync ?? this.enableLegacyCommentSync,
      useWhiteVideoHeader: useWhiteVideoHeader ?? this.useWhiteVideoHeader,
    );
  }

  @override
  String toString() => 'PostContentStyle.$name';
}

/// Action button style configuration
/// Currently identical for both styles, but separated for future customization
class PostActionStyle {
  const PostActionStyle({
    required this.iconSize,
    required this.textStyle,
    this.reshareIcon,
    this.sendIconSize = 18,
    this.rowSpacing = 0,
  });

  final double iconSize;
  final TextStyle textStyle;
  final IconData? reshareIcon;
  final double sendIconSize;
  final double rowSpacing;

  const PostActionStyle.modern()
      : iconSize = AgendaSpacing.smallIconSize,
        textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
        reshareIcon = Icons.repeat,
        sendIconSize = 18,
        rowSpacing = 0;

  const PostActionStyle.classic()
      : iconSize = AgendaSpacing.smallIconSize,
        textStyle = const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
        reshareIcon = Icons.repeat,
        sendIconSize = 18,
        rowSpacing = 0;
}
