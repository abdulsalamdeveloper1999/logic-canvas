import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';

/// How long an element takes to move or change colour between steps. Short
/// enough to keep up with fast stepping, long enough for the eye to follow.
const Duration kVizTransition = Duration(milliseconds: 320);
const Curve kVizCurve = Curves.easeOutCubic;

/// Colours for each [VizState], resolved against the app theme so the
/// animations read correctly in both light and dark mode.
class VizPalette {
  final Color fill;
  final Color border;
  final Color text;

  const VizPalette({
    required this.fill,
    required this.border,
    required this.text,
  });

  static VizPalette of(BuildContext context, VizState state) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    Color mix(Color base, double amount) =>
        Color.alphaBlend(base.withValues(alpha: amount), scheme.surface);

    return switch (state) {
      VizState.idle => VizPalette(
        fill: mix(scheme.onSurface, dark ? 0.08 : 0.05),
        border: scheme.outlineVariant,
        text: scheme.onSurface,
      ),
      VizState.active => VizPalette(
        fill: mix(scheme.primary, dark ? 0.34 : 0.18),
        border: scheme.primary,
        text: dark ? scheme.onSurface : scheme.primary,
      ),
      VizState.compare => VizPalette(
        fill: mix(const Color(0xFFE0A11B), dark ? 0.32 : 0.20),
        border: const Color(0xFFE0A11B),
        text: dark ? const Color(0xFFF2C87A) : const Color(0xFF7A5407),
      ),
      VizState.success => VizPalette(
        fill: mix(const Color(0xFF1E9E6A), dark ? 0.34 : 0.20),
        border: const Color(0xFF1E9E6A),
        text: dark ? const Color(0xFF7FDCB6) : const Color(0xFF0E5C3D),
      ),
      VizState.fail => VizPalette(
        fill: mix(const Color(0xFFD1483A), dark ? 0.30 : 0.16),
        border: const Color(0xFFD1483A),
        text: dark ? const Color(0xFFF0A79D) : const Color(0xFF8C2A1F),
      ),
      VizState.done => VizPalette(
        fill: mix(scheme.onSurface, dark ? 0.05 : 0.03),
        border: scheme.outlineVariant.withValues(alpha: 0.5),
        text: scheme.onSurfaceVariant,
      ),
      VizState.dim => VizPalette(
        fill: Colors.transparent,
        border: scheme.outlineVariant.withValues(alpha: 0.28),
        text: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    };
  }
}

const double _kCell = 48;
const double _kGap = 8;
const double _kPointerRow = 26;
const double _kBracketRow = 22;

TextStyle _mono(BuildContext context, {double size = 15, FontWeight? weight}) {
  return TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: const ['Courier New', 'monospace'],
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

Widget _panelTitle(BuildContext context, String? title) {
  if (title == null || title.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Renders any [VizScene]. New scene types only need a case here.
class VizSceneView extends StatelessWidget {
  final VizScene scene;

  const VizSceneView({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    return switch (scene) {
      ArrayScene s => _ArrayView(scene: s),
      MapScene s => _MapView(scene: s),
      StackScene s => _StackView(scene: s),
      QueueScene s => _QueueView(scene: s),
      TreeScene s => _TreeView(scene: s),
      LinkedListScene s => _LinkedListView(scene: s),
      GridScene s => _GridView(scene: s),
      GraphScene s => _GraphView(scene: s),
      ValueScene s => _ValueView(scene: s),
    };
  }
}

// -------------------------------------------------------------------- grid

class _GridView extends StatelessWidget {
  final GridScene scene;
  const _GridView({required this.scene});

  static const double _cell = 38;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var r = 0; r < scene.rows; r++)
                Padding(
                  padding: const EdgeInsets.only(bottom: _gap),
                  child: Row(
                    children: [
                      for (var c = 0; c < scene.columns; c++)
                        Padding(
                          padding: const EdgeInsets.only(right: _gap),
                          child: _GridCell(
                            label: scene.cells[r][c],
                            state:
                                scene.states[scene.indexOf(r, c)] ??
                                VizState.idle,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label;
  final VizState state;

  const _GridCell({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = VizPalette.of(context, state);
    return AnimatedContainer(
      duration: kVizTransition,
      curve: kVizCurve,
      width: _GridView._cell,
      height: _GridView._cell,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: palette.border,
          width: state == VizState.idle || state == VizState.dim ? 1 : 2,
        ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: kVizTransition,
        style: _mono(context, size: 13).copyWith(color: palette.text),
        child: Text(label),
      ),
    );
  }
}

// ------------------------------------------------------------------- graph

class _GraphView extends StatelessWidget {
  final GraphScene scene;
  const _GraphView({required this.scene});

  static const double _node = 40;
  static const double _height = 220;

  /// Nodes are spread evenly around a circle, which keeps every edge visible
  /// without needing a layout engine.
  static Offset centerOf(int index, int count, Size size) {
    if (count == 1) return Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _node / 2 - 6;
    final angle = (2 * math.pi * index / count) - math.pi / 2;
    return Offset(
      size.width / 2 + radius * math.cos(angle),
      size.height / 2 + radius * math.sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(math.max(constraints.maxWidth, 240.0), _height);
            return SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _GraphEdgePainter(
                      scene: scene,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  for (var i = 0; i < scene.nodes.length; i++)
                    Positioned(
                      left:
                          centerOf(i, scene.nodes.length, size).dx - _node / 2,
                      top: centerOf(i, scene.nodes.length, size).dy - _node / 2,
                      child: _TreeNode(
                        label: scene.nodes[i],
                        state: scene.states[i] ?? VizState.idle,
                        size: _node,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GraphEdgePainter extends CustomPainter {
  final GraphScene scene;
  final Color color;
  final Color activeColor;

  _GraphEdgePainter({
    required this.scene,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = scene.nodes.length;

    for (var i = 0; i < scene.edges.length; i++) {
      final edge = scene.edges[i];
      if (edge.from >= count || edge.to >= count) continue;

      final active = scene.activeEdges.contains(i);
      final paint = Paint()
        ..color = active ? activeColor : color
        ..strokeWidth = active ? 2.6 : 1.6
        ..style = PaintingStyle.stroke;

      final from = _GraphView.centerOf(edge.from, count, size);
      final to = _GraphView.centerOf(edge.to, count, size);

      // Stop short of the node circles so arrowheads stay readable.
      final direction = to - from;
      final distance = direction.distance;
      if (distance < 1) continue;
      final unit = direction / distance;
      final start = from + unit * (_GraphView._node / 2);
      final end = to - unit * (_GraphView._node / 2);

      canvas.drawLine(start, end, paint);

      if (scene.directed) {
        const head = 8.0;
        final normal = Offset(-unit.dy, unit.dx);
        final base = end - unit * head;
        final path = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            base.dx + normal.dx * head / 2,
            base.dy + normal.dy * head / 2,
          )
          ..lineTo(
            base.dx - normal.dx * head / 2,
            base.dy - normal.dy * head / 2,
          )
          ..close();
        canvas.drawPath(path, Paint()..color = paint.color);
      }
    }
  }

  @override
  bool shouldRepaint(_GraphEdgePainter old) => true;
}

// ------------------------------------------------------------------- array

class _ArrayView extends StatelessWidget {
  final ArrayScene scene;
  const _ArrayView({required this.scene});

  double _xOf(int index) => index * (_kCell + _kGap);

  @override
  Widget build(BuildContext context) {
    final count = scene.values.length;
    final width = count == 0 ? 0.0 : count * (_kCell + _kGap) - _kGap;

    // Several pointers can land on the same cell; stack them under it.
    final byIndex = <int, List<String>>{};
    for (final entry in scene.pointers.entries) {
      byIndex.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final maxStacked = byIndex.values.fold<int>(
      1,
      (acc, labels) => math.max(acc, labels.length),
    );
    final pointerHeight = scene.pointers.isEmpty
        ? 0.0
        : _kPointerRow * maxStacked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scene.window != null)
                  SizedBox(
                    height: _kBracketRow,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedPositioned(
                          duration: kVizTransition,
                          curve: kVizCurve,
                          left: _xOf(scene.window!.start),
                          width:
                              (scene.window!.end - scene.window!.start + 1) *
                                  (_kCell + _kGap) -
                              _kGap,
                          top: 0,
                          child: _WindowBracket(label: scene.windowLabel),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: _kCell,
                  child: Stack(
                    children: [
                      for (var i = 0; i < count; i++)
                        Positioned(
                          left: _xOf(i),
                          top: 0,
                          child: _Cell(
                            key: ValueKey('cell-$i'),
                            label: scene.values[i],
                            state: scene.states[i] ?? VizState.idle,
                          ),
                        ),
                    ],
                  ),
                ),
                // Index ruler — beginners lose track of position without it.
                SizedBox(
                  height: 16,
                  child: Stack(
                    children: [
                      for (var i = 0; i < count; i++)
                        Positioned(
                          left: _xOf(i),
                          width: _kCell,
                          top: 0,
                          child: Text(
                            '$i',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (pointerHeight > 0)
                  SizedBox(
                    height: pointerHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final entry in scene.pointers.entries)
                          AnimatedPositioned(
                            key: ValueKey('ptr-${entry.key}'),
                            duration: kVizTransition,
                            curve: kVizCurve,
                            left: _xOf(entry.value),
                            width: _kCell,
                            top:
                                _kPointerRow *
                                byIndex[entry.value]!.indexOf(entry.key),
                            child: _PointerChip(label: entry.key),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final VizState state;

  const _Cell({super.key, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = VizPalette.of(context, state);
    return AnimatedContainer(
      duration: kVizTransition,
      curve: kVizCurve,
      width: _kCell,
      height: _kCell,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: palette.border,
          width: state == VizState.idle || state == VizState.dim ? 1 : 2,
        ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: kVizTransition,
        style: _mono(context, size: 16).copyWith(color: palette.text),
        child: Text(label),
      ),
    );
  }
}

class _PointerChip extends StatelessWidget {
  final String label;
  const _PointerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_drop_up_rounded, size: 14, color: scheme.primary),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _WindowBracket extends StatelessWidget {
  final String? label;
  const _WindowBracket({this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label != null)
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: scheme.primary, width: 2),
              right: BorderSide(color: scheme.primary, width: 2),
              bottom: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------- map

class _MapView extends StatelessWidget {
  final MapScene scene;
  const _MapView({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        if (scene.entries.isEmpty)
          _EmptyNote(label: scene.emptyLabel)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in scene.entries)
                _Pill(
                  key: ValueKey('map-${entry.key}'),
                  state: entry.state,
                  child: RichText(
                    text: TextSpan(
                      style: _mono(context, size: 13),
                      children: [
                        TextSpan(text: entry.key),
                        TextSpan(
                          text: '  →  ',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(text: entry.value),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------- stack

class _StackView extends StatelessWidget {
  final StackScene scene;
  const _StackView({required this.scene});

  @override
  Widget build(BuildContext context) {
    // Drawn top-down so the most recent push sits at the top, as people
    // picture a stack of plates.
    final items = scene.items.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        if (items.isEmpty)
          _EmptyNote(label: scene.emptyLabel)
        else
          AnimatedSize(
            duration: kVizTransition,
            curve: kVizCurve,
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        _Pill(
                          state: items[i].state,
                          minWidth: 56,
                          child: Text(
                            items[i].value,
                            style: _mono(context, size: 15),
                          ),
                        ),
                        if (i == 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '← top',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------- queue

class _QueueView extends StatelessWidget {
  final QueueScene scene;
  const _QueueView({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        if (scene.items.isEmpty)
          _EmptyNote(label: scene.emptyLabel)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AnimatedSize(
              duration: kVizTransition,
              curve: kVizCurve,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      'front →',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final item in scene.items)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Pill(
                        state: item.state,
                        minWidth: 40,
                        child: Text(
                          item.value,
                          style: _mono(context, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------------- tree

class _TreeView extends StatelessWidget {
  final TreeScene scene;
  const _TreeView({required this.scene});

  static const double _node = 40;
  static const double _levelHeight = 64;

  @override
  Widget build(BuildContext context) {
    final depth = scene.depth;
    final height = depth * _levelHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, 240.0);
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: _TreeEdgePainter(
                      scene: scene,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      levelHeight: _levelHeight,
                    ),
                  ),
                  for (var i = 0; i < scene.heap.length; i++)
                    if (scene.heap[i] != null)
                      Positioned(
                        left: _centerOf(i, width).dx - _node / 2,
                        top: _centerOf(i, width).dy - _node / 2,
                        child: _TreeNode(
                          label: scene.heap[i]!,
                          state: scene.states[i] ?? VizState.idle,
                          size: _node,
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Level-order index -> centre point. Level L holds 2^L evenly spread slots.
  static Offset _centerOf(int index, double width) {
    final level = (math.log(index + 1) / math.ln2).floor();
    final slotsInLevel = 1 << level;
    final slot = index - (slotsInLevel - 1);
    final x = width * (slot + 0.5) / slotsInLevel;
    final y = level * _levelHeight + _node / 2 + 4;
    return Offset(x, y);
  }
}

class _TreeEdgePainter extends CustomPainter {
  final TreeScene scene;
  final Color color;
  final double levelHeight;

  _TreeEdgePainter({
    required this.scene,
    required this.color,
    required this.levelHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < scene.heap.length; i++) {
      if (scene.heap[i] == null) continue;
      for (final child in [i * 2 + 1, i * 2 + 2]) {
        if (child >= scene.heap.length || scene.heap[child] == null) continue;
        canvas.drawLine(
          _TreeView._centerOf(i, size.width),
          _TreeView._centerOf(child, size.width),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TreeEdgePainter old) =>
      old.scene != scene || old.color != color;
}

class _TreeNode extends StatelessWidget {
  final String label;
  final VizState state;
  final double size;

  const _TreeNode({
    required this.label,
    required this.state,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final palette = VizPalette.of(context, state);
    return AnimatedContainer(
      duration: kVizTransition,
      curve: kVizCurve,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.fill == Colors.transparent
            ? Theme.of(context).colorScheme.surface
            : palette.fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: palette.border,
          width: state == VizState.idle ? 1.4 : 2.4,
        ),
      ),
      child: Text(
        label,
        style: _mono(context, size: 14).copyWith(color: palette.text),
      ),
    );
  }
}

// ------------------------------------------------------------- linked list

class _LinkedListView extends StatelessWidget {
  final LinkedListScene scene;
  const _LinkedListView({required this.scene});

  static const double _node = 48;
  static const double _slot = 96;

  @override
  Widget build(BuildContext context) {
    final count = scene.values.length;
    // One extra slot on the right for the null terminator.
    final width = (count + 1) * _slot;

    final byIndex = <int?, List<String>>{};
    for (final entry in scene.pointers.entries) {
      byIndex.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final maxStacked = byIndex.values.fold<int>(
      1,
      (acc, labels) => math.max(acc, labels.length),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _node + 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(width, _node + 28),
                        painter: _LinkPainter(
                          scene: scene,
                          slot: _slot,
                          node: _node,
                          color: Theme.of(context).colorScheme.primary,
                          nullColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      for (var i = 0; i < count; i++)
                        Positioned(
                          left: i * _slot,
                          top: 0,
                          child: _Cell(
                            key: ValueKey('node-$i'),
                            label: scene.values[i],
                            state: scene.states[i] ?? VizState.idle,
                          ),
                        ),
                      Positioned(
                        left: count * _slot,
                        top: 0,
                        child: SizedBox(
                          width: _node,
                          height: _node,
                          child: Center(
                            child: Text(
                              'null',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _kPointerRow * maxStacked,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final entry in scene.pointers.entries)
                        AnimatedPositioned(
                          key: ValueKey('llptr-${entry.key}'),
                          duration: kVizTransition,
                          curve: kVizCurve,
                          left: (entry.value ?? count) * _slot,
                          width: _node,
                          top:
                              _kPointerRow *
                              byIndex[entry.value]!.indexOf(entry.key),
                          child: _PointerChip(label: entry.key),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws each node's outgoing link. Forward links run above the nodes,
/// reversed links curve underneath, so a reversal is visible at a glance.
class _LinkPainter extends CustomPainter {
  final LinkedListScene scene;
  final double slot;
  final double node;
  final Color color;
  final Color nullColor;

  _LinkPainter({
    required this.scene,
    required this.slot,
    required this.node,
    required this.color,
    required this.nullColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < scene.values.length; i++) {
      final target = scene.next[i];
      final isNull = target == null;
      final paint = Paint()
        ..color = isNull ? nullColor : color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final fromCenter = Offset(i * slot + node / 2, node / 2);

      if (isNull) {
        // Point at the null marker in the trailing slot.
        final to = Offset(scene.values.length * slot + 4, node / 2);
        if (i != scene.values.length - 1) continue;
        _arrow(canvas, Offset(fromCenter.dx + node / 2, node / 2), to, paint);
        continue;
      }

      final toCenter = Offset(target * slot + node / 2, node / 2);
      final forward = target > i;

      if (forward) {
        _arrow(
          canvas,
          Offset(fromCenter.dx + node / 2 + 2, node / 2),
          Offset(toCenter.dx - node / 2 - 2, node / 2),
          paint,
        );
      } else {
        // Reversed: dip below the row so it reads as a flipped arrow.
        final start = Offset(fromCenter.dx - node / 2 - 2, node / 2 + 6);
        final end = Offset(toCenter.dx + node / 2 + 2, node / 2 + 6);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            (start.dx + end.dx) / 2,
            node / 2 + 26,
            end.dx,
            end.dy,
          );
        canvas.drawPath(path, paint);
        _arrowHead(canvas, end, const Offset(-1, 0), paint);
      }
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    if ((to - from).distance < 2) return;
    canvas.drawLine(from, to, paint);
    final direction = (to - from);
    _arrowHead(canvas, to, direction / direction.distance, paint);
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset unit, Paint paint) {
    const size = 6.0;
    final normal = Offset(-unit.dy, unit.dx);
    final base = tip - unit * size;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * size / 2, base.dy + normal.dy * size / 2)
      ..lineTo(base.dx - normal.dx * size / 2, base.dy - normal.dy * size / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  @override
  bool shouldRepaint(_LinkPainter old) => true;
}

// ------------------------------------------------------------------ values

class _ValueView extends StatelessWidget {
  final ValueScene scene;
  const _ValueView({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelTitle(context, scene.title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reading in scene.readings)
              _Pill(
                state: reading.state,
                child: RichText(
                  text: TextSpan(
                    style: _mono(context, size: 13),
                    children: [
                      TextSpan(
                        text: '${reading.label} = ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(text: reading.value),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ shared

class _Pill extends StatelessWidget {
  final Widget child;
  final VizState state;
  final double minWidth;

  const _Pill({
    super.key,
    required this.child,
    required this.state,
    this.minWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = VizPalette.of(context, state);
    return AnimatedContainer(
      duration: kVizTransition,
      curve: kVizCurve,
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: palette.border,
          width: state == VizState.idle ? 1 : 1.8,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String label;
  const _EmptyNote({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
