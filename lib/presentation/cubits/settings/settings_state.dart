import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ThemeMode themeMode,
    required Color strokeColor,
    required double strokeWidth,
    required bool isEraser,
    required BackgroundPattern pattern,
    required bool showSidebar,
    @Default(ToolMode.pen) ToolMode toolMode,
    @Default(1.0) double zoomLevel,
    @Default(Offset.zero) Offset panOffset,
    @Default(false) bool autoHideSidebar,
    @Default(true) bool showToolbar,
    @Default(false) bool enableShapeDetection,
    @Default(false) bool enableHandwritingRecognition,
    // Ephemeral counter used to trigger "drop selected icon onto board" events.
    // Intentionally not persisted in Hive.
    @Default(0) int iconSelectionNonce,
    String? selectedIconPath,
    Offset? hoverPosition,
  }) = _SettingsState;

  factory SettingsState.initial() => const SettingsState(
    themeMode: ThemeMode.dark,
    strokeColor: Colors.white,
    strokeWidth: 3.0,
    isEraser: false,
    pattern: BackgroundPattern.grid,
    showSidebar: false,
    toolMode: ToolMode.pen,
    zoomLevel: 1.0,
    panOffset: Offset.zero,
    autoHideSidebar: false,
    showToolbar: true,
  );

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == (json['themeMode'] as String? ?? 'dark'),
        orElse: () => ThemeMode.dark,
      ),
      strokeColor: Color(json['strokeColor'] as int? ?? Colors.white.toARGB32()),
      // Keep in sync with the UI slider range to avoid runtime assertions.
      strokeWidth: (json['strokeWidth'] as num? ?? 3.0).toDouble().clamp(1.0, 50.0),
      isEraser: json['isEraser'] as bool? ?? false,
      pattern: BackgroundPattern.values.firstWhere(
        (e) => e.name == (json['pattern'] as String? ?? 'grid'),
        orElse: () => BackgroundPattern.grid,
      ),
      showSidebar: json['showSidebar'] as bool? ?? false,
      toolMode: ToolMode.values.firstWhere(
        (e) => e.name == (json['toolMode'] as String? ?? 'pen'),
        orElse: () => ToolMode.pen,
      ),
      zoomLevel: (json['zoomLevel'] as num? ?? 1.0).toDouble(),
      panOffset: Offset(
        (json['panOffsetX'] as num? ?? 0.0).toDouble(),
        (json['panOffsetY'] as num? ?? 0.0).toDouble(),
      ),
      autoHideSidebar: json['autoHideSidebar'] as bool? ?? false,
      showToolbar: json['showToolbar'] as bool? ?? true,
      enableShapeDetection: json['enableShapeDetection'] as bool? ?? false,
      enableHandwritingRecognition:
          json['enableHandwritingRecognition'] as bool? ?? false,
      iconSelectionNonce: 0,
      selectedIconPath: json['selectedIconPath'] as String?,
    );
  }
}

extension SettingsStateX on SettingsState {
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'strokeColor': strokeColor.toARGB32(),
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'pattern': pattern.name,
      'showSidebar': showSidebar,
      'toolMode': toolMode.name,
      'zoomLevel': zoomLevel,
      'panOffsetX': panOffset.dx,
      'panOffsetY': panOffset.dy,
      'autoHideSidebar': autoHideSidebar,
      'showToolbar': showToolbar,
      'enableShapeDetection': enableShapeDetection,
      'enableHandwritingRecognition': enableHandwritingRecognition,
      'selectedIconPath': selectedIconPath,
    };
  }
}

enum BackgroundPattern { none, grid, lines }

enum ToolMode { pen, eraser, hand, diagram, connector }
