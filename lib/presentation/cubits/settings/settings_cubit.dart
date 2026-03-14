import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/data/services/ml_shape_service.dart';
import 'package:logic_canvas/data/services/handwriting_service.dart';
import 'settings_state.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> {
  static const String _boxName = 'settings';
  static const String _settingsKey = 'user_settings';
  final HandwritingRecognitionService _handwritingService;
  final MLShapeService _mlShapeService;

  SettingsCubit(this._handwritingService, this._mlShapeService)
    : super(SettingsState.initial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(_boxName);
    final settingsMap = box.get(_settingsKey);
    if (settingsMap != null) {
      final settings = SettingsState.fromJson(
        Map<String, dynamic>.from(settingsMap),
      );
      emit(settings);
    }
  }

  Future<void> _saveSettings() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_settingsKey, state.toJson());
  }

  void toggleTheme() {
    final newThemeMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    // Auto-adjust default pen color to ensure visibility
    Color newStrokeColor = state.strokeColor;

    // If switching to Light Mode and color is too light, switch to Black
    if (newThemeMode == ThemeMode.light &&
        (state.strokeColor == Colors.white ||
            state.strokeColor.computeLuminance() > 0.8)) {
      newStrokeColor = Colors.black;
    }
    // If switching to Dark Mode and color is too dark, switch to White
    else if (newThemeMode == ThemeMode.dark &&
        (state.strokeColor == Colors.black ||
            state.strokeColor.computeLuminance() < 0.2)) {
      newStrokeColor = Colors.white;
    }

    emit(state.copyWith(themeMode: newThemeMode, strokeColor: newStrokeColor));
    _saveSettings();
  }

  @override
  Future<void> close() {
    _handwritingService.dispose();
    _mlShapeService.dispose();
    return super.close();
  }

  void setStrokeColor(Color color) {
    emit(state.copyWith(strokeColor: color, isEraser: false));
    _saveSettings();
  }

  void setStrokeWidth(double width) {
    emit(state.copyWith(strokeWidth: width));
    _saveSettings();
  }

  void setEraser(bool isEraser) {
    emit(
      state.copyWith(
        isEraser: isEraser,
        toolMode: isEraser ? ToolMode.eraser : ToolMode.pen,
      ),
    );
    _saveSettings();
  }

  void setToolMode(ToolMode mode) {
    emit(state.copyWith(toolMode: mode, isEraser: mode == ToolMode.eraser));
    _saveSettings();
  }

  void setZoom(double zoom) {
    emit(state.copyWith(zoomLevel: zoom.clamp(0.5, 3.0)));
    _saveSettings();
  }

  void updatePan(Offset delta) {
    emit(state.copyWith(panOffset: state.panOffset + delta));
  }

  void resetTransform() {
    emit(state.copyWith(zoomLevel: 1.0, panOffset: Offset.zero));
  }

  void setPattern(BackgroundPattern pattern) {
    emit(state.copyWith(pattern: pattern));
    _saveSettings();
  }

  void toggleSidebar() {
    emit(state.copyWith(showSidebar: !state.showSidebar));
    _saveSettings();
  }

  void toggleAutoHideSidebar() {
    emit(state.copyWith(autoHideSidebar: !state.autoHideSidebar));
    _saveSettings();
  }

  void toggleToolbar() {
    emit(state.copyWith(showToolbar: !state.showToolbar));
    _saveSettings();
  }

  void hideSidebar() {
    emit(state.copyWith(showSidebar: false));
  }

  void setBrushPreset(double width) {
    emit(
      state.copyWith(
        strokeWidth: width,
        toolMode: ToolMode.pen,
        isEraser: false,
      ),
    );
  }

  void setHoverPosition(Offset? position) {
    emit(state.copyWith(hoverPosition: position));
  }

  void toggleShapeDetection() {
    final bool isHandwritingActive = state.enableHandwritingRecognition;
    final bool currentShapeValue = state.enableShapeDetection;
    final bool newShapeValue = !currentShapeValue;

    emit(
      state.copyWith(
        enableShapeDetection: newShapeValue,
        enableHandwritingRecognition: newShapeValue
            ? false
            : isHandwritingActive,
      ),
    );

    _saveSettings();
  }

  void toggleHandwritingRecognition() {
    final bool isShapeActive = state.enableShapeDetection;
    final bool currentHandwritingValue = state.enableHandwritingRecognition;
    final bool newHandwritingValue = !currentHandwritingValue;

    emit(
      state.copyWith(
        enableHandwritingRecognition: newHandwritingValue,
        enableShapeDetection: newHandwritingValue ? false : isShapeActive,
      ),
    );

    _saveSettings();
  }

  void setSelectedIconPath(String? path) {
    emit(state.copyWith(selectedIconPath: path, toolMode: ToolMode.diagram));
    _saveSettings();
  }
}
