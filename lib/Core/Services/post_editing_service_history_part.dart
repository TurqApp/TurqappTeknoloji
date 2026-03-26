part of 'post_editing_service.dart';

extension PostEditingServiceHistoryPart on PostEditingService {
  void recordAction({
    required String type,
    required Map<String, dynamic> beforeState,
    required Map<String, dynamic> afterState,
  }) {
    final action = EditAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      beforeState: beforeState,
      afterState: afterState,
      timestamp: DateTime.now(),
    );

    _undoStack.add(action);
    _redoStack.clear();

    if (_undoStack.length > _kPostEditingMaxUndoActions) {
      _undoStack.removeAt(0);
    }
  }

  Map<String, dynamic>? undo() {
    if (_undoStack.isEmpty) return null;

    final lastAction = _undoStack.removeLast();
    _redoStack.add(lastAction);

    return lastAction.beforeState;
  }

  Map<String, dynamic>? redo() {
    if (_redoStack.isEmpty) return null;

    final lastUndone = _redoStack.removeLast();
    _undoStack.add(lastUndone);

    return lastUndone.afterState;
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void updateFormatting(TextFormatting newFormatting) {
    final oldFormatting = _currentFormatting.value;

    recordAction(
      type: 'formatting',
      beforeState: {'formatting': oldFormatting.toJson()},
      afterState: {'formatting': newFormatting.toJson()},
    );

    _currentFormatting.value = newFormatting;
  }

  void toggleBold() {
    updateFormatting(_currentFormatting.value.copyWith(
      bold: !_currentFormatting.value.bold,
    ));
  }

  void toggleItalic() {
    updateFormatting(_currentFormatting.value.copyWith(
      italic: !_currentFormatting.value.italic,
    ));
  }

  void toggleUnderline() {
    updateFormatting(_currentFormatting.value.copyWith(
      underline: !_currentFormatting.value.underline,
    ));
  }

  void changeFontSize(double newSize) {
    updateFormatting(_currentFormatting.value.copyWith(
      fontSize: newSize.clamp(10.0, 24.0),
    ));
  }

  void changeTextColor(Color newColor) {
    updateFormatting(_currentFormatting.value.copyWith(
      textColor: newColor,
    ));
  }
}
