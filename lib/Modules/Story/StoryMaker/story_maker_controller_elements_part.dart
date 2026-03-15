part of 'story_maker_controller.dart';

extension StoryMakerControllerElementsPart on StoryMakerController {
  void bringToFront(StoryElement element) {
    element.zIndex = ++_zIndexCounter;
    elements.refresh();
  }

  void toggleVideoMute(StoryElement element) {
    if (element.type != StoryElementType.video) return;
    _saveState();
    element.isMuted = !element.isMuted;
    elements.refresh();
  }

  void removeElement(StoryElement element) {
    _saveState();
    elements.remove(element);
    elements.refresh();
  }

  void _saveState() {
    final currentState = elements
        .map((e) => StoryElement(
              id: e.id,
              type: e.type,
              content: e.content,
              width: e.width,
              height: e.height,
              position: e.position,
              rotation: e.rotation,
              zIndex: e.zIndex,
              isMuted: e.isMuted,
              fontSize: e.fontSize,
              aspectRatio: e.aspectRatio,
              textColor: e.textColor,
              textBgColor: e.textBgColor,
              hasTextBg: e.hasTextBg,
              textAlign: e.textAlign,
              fontWeight: e.fontWeight,
              italic: e.italic,
              underline: e.underline,
              shadowBlur: e.shadowBlur,
              shadowOpacity: e.shadowOpacity,
              fontFamily: e.fontFamily,
              hasOutline: e.hasOutline,
              outlineColor: e.outlineColor,
              stickerType: e.stickerType,
              stickerData: e.stickerData,
              mediaLookPreset: e.mediaLookPreset,
            ))
        .toList();

    _historyIndex++;
    if (_historyIndex < _history.length) {
      _history.removeRange(_historyIndex, _history.length);
    }
    _history.add(currentState);

    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }

    _updateUndoRedoState();
  }

  void _updateUndoRedoState() {
    canUndo.value = _historyIndex > 0;
    canRedo.value = _historyIndex < _history.length - 1;
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      elements.assignAll(_history[_historyIndex]);
      elements.refresh();
      _updateUndoRedoState();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      elements.assignAll(_history[_historyIndex]);
      elements.refresh();
      _updateUndoRedoState();
    }
  }

  void addTextElement(String text) {
    _saveState();
    const width = 250.0;
    const height = 120.0;
    elements.add(
      StoryElement(
        type: StoryElementType.text,
        content: text,
        width: width,
        height: height,
        position: Offset(100, 100),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        fontSize: 20,
        aspectRatio: double.parse((width / height).toStringAsFixed(4)),
        mediaLookPreset: 'original',
      ),
    );
  }

  void addStyledTextElement(
    String text, {
    int textColor = 0xFFFFFFFF,
    int textBgColor = 0x66000000,
    bool hasTextBg = true,
    String textAlign = 'center',
    String fontWeight = 'regular',
    bool italic = false,
    bool underline = false,
    double shadowBlur = 2.0,
    double shadowOpacity = 0.6,
    String fontFamily = 'MontserratMedium',
    bool hasOutline = false,
    int outlineColor = 0xFF000000,
  }) {
    _saveState();
    const width = 280.0;
    const height = 140.0;
    final screenW = Get.width;
    final keyboardInset = Get.mediaQuery.viewInsets.bottom;
    final playgroundHeight =
        _availablePlaygroundHeight(includeMediaLookTools: false);
    final dx = (screenW - width) / 2;
    double dy = (playgroundHeight - height) / 2;
    if (keyboardInset > 0) {
      final visiblePlaygroundHeight =
          (playgroundHeight - keyboardInset).clamp(120.0, playgroundHeight);
      dy = (visiblePlaygroundHeight - height) / 2;
    }
    elements.add(
      StoryElement(
        type: StoryElementType.text,
        content: text,
        width: width,
        height: height,
        position: Offset(dx, dy),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        fontSize: 28,
        aspectRatio: double.parse((width / height).toStringAsFixed(4)),
        textColor: textColor,
        textBgColor: textBgColor,
        hasTextBg: hasTextBg,
        textAlign: textAlign,
        fontWeight: fontWeight,
        italic: italic,
        underline: underline,
        shadowBlur: shadowBlur,
        shadowOpacity: shadowOpacity,
        fontFamily: fontFamily,
        hasOutline: hasOutline,
        outlineColor: outlineColor,
        mediaLookPreset: 'original',
      ),
    );
  }

  void addGifFromUrl(String gifUrl) {
    final clean = gifUrl.trim();
    if (clean.isEmpty) return;
    _saveState();
    final width = Get.width * 0.55;
    final height = width;
    elements.add(
      StoryElement(
        type: StoryElementType.gif,
        content: clean,
        width: width,
        height: height,
        position: Offset((Get.width - width) / 2, Get.height * 0.30),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        aspectRatio: 1.0,
        mediaLookPreset: 'original',
      ),
    );
    elements.refresh();
  }

  void addSticker({
    required String stickerType,
    required String label,
    String data = '',
  }) {
    final cleanLabel = label.trim();
    if (cleanLabel.isEmpty) return;
    _saveState();
    final width = Get.width * 0.62;
    const height = 58.0;
    elements.add(
      StoryElement(
        type: StoryElementType.sticker,
        content: cleanLabel,
        width: width,
        height: height,
        position: Offset((Get.width - width) / 2, Get.height * 0.35),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        aspectRatio: width / height,
        stickerType: stickerType,
        stickerData: data.trim(),
        textColor: 0xFF111111,
        textBgColor: 0xF5FFFFFF,
        hasTextBg: true,
        fontSize: 16,
        mediaLookPreset: 'original',
      ),
    );
    elements.refresh();
  }

  void editTextElement({
    required StoryElement element,
    required String text,
    required int textColor,
    required int textBgColor,
    required bool hasTextBg,
    required String textAlign,
    required String fontWeight,
    bool? italic,
    bool? underline,
    double? shadowBlur,
    double? shadowOpacity,
    String? fontFamily,
    bool? hasOutline,
    int? outlineColor,
  }) {
    _saveState();
    element.content = text;
    element.textColor = textColor;
    element.textBgColor = textBgColor;
    element.hasTextBg = hasTextBg;
    element.textAlign = textAlign;
    element.fontWeight = fontWeight;
    if (italic != null) element.italic = italic;
    if (underline != null) element.underline = underline;
    if (shadowBlur != null) element.shadowBlur = shadowBlur;
    if (shadowOpacity != null) element.shadowOpacity = shadowOpacity;
    if (fontFamily != null) element.fontFamily = fontFamily;
    if (hasOutline != null) element.hasOutline = hasOutline;
    if (outlineColor != null) element.outlineColor = outlineColor;
    elements.refresh();
  }

  void openDrawing() {
    Get.to<String>(
      () => DrawingScreen(onSave: (path) {
        _saveState();
        const size = 300.0;
        elements.add(
          StoryElement(
            type: StoryElementType.drawing,
            content: path,
            width: size,
            height: size,
            position: Offset(100, 100),
            rotation: 0,
            zIndex: ++_zIndexCounter,
            aspectRatio: 1.0,
            mediaLookPreset: 'original',
          ),
        );
      }),
    );
  }
}
