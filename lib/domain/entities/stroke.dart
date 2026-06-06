import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'stroke.freezed.dart';

enum StrokeType { pen, circle, rectangle, triangle, diamond, text, icon, connector }

@freezed
class Stroke with _$Stroke {
  const factory Stroke({
    required List<Offset> points,
    required Color color,
    required double strokeWidth,
    @Default(false) bool isEraser,
    @Default(StrokeType.pen) StrokeType type,
    String? text,
    String? iconPath,
    @Default(1.0) double scale,
    @Default(0.0) double rotation,
    @Default(false) bool isSelected,
  }) = _Stroke;

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'] as double, p['dy'] as double))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
      type: StrokeType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'pen'),
        orElse: () => StrokeType.pen,
      ),
      text: json['text'] as String?,
      iconPath: json['iconPath'] as String?,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }
}

extension StrokeX on Stroke {
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'type': type.name,
      'text': text,
      'iconPath': iconPath,
      'scale': scale,
      'rotation': rotation,
      'isSelected': isSelected,
    };
  }
}

// Minimal Equatable wrapper if needed for specific bloc comparisons, 
// though Freezed handles equality well. User explicitly asked for Equatable.
class StrokeEquatable extends Equatable {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  const StrokeEquatable({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isEraser,
  });

  @override
  List<Object?> get props => [points, color, strokeWidth, isEraser];
}
