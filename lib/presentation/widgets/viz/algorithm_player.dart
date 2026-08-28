import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logic_canvas/domain/entities/viz_scene.dart';
import 'package:logic_canvas/presentation/widgets/viz/viz_scene_views.dart';

/// Time each step is held during autoplay at 1x. Slow enough to read the
/// caption, which is the part that actually teaches.
const Duration _kStepDuration = Duration(milliseconds: 2600);

/// Plays an [AlgorithmTrace] frame by frame with narration, a highlighted
/// pseudocode line, and manual step controls.
///
/// Autoplay stops at the end rather than looping: the closing step carries the
/// takeaway, and looping past it hides the conclusion.
class AlgorithmPlayer extends StatefulWidget {
  final AlgorithmTrace trace;

  /// Offered as a button on the final step, so the learner can carry the idea
  /// onto their own whiteboard.
  final void Function(AlgorithmTrace trace)? onCopyToBoard;

  const AlgorithmPlayer({super.key, required this.trace, this.onCopyToBoard});

  @override
  State<AlgorithmPlayer> createState() => _AlgorithmPlayerState();
}

class _AlgorithmPlayerState extends State<AlgorithmPlayer> {
  int _index = 0;
  bool _playing = false;
  double _speed = 1.0;
  Timer? _timer;

  VizStep get _step => widget.trace.steps[_index];
  bool get _atEnd => _index >= widget.trace.steps.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer.periodic(
      Duration(milliseconds: (_kStepDuration.inMilliseconds / _speed).round()),
      (_) {
        if (_atEnd) {
          _setPlaying(false);
          return;
        }
        setState(() => _index++);
      },
    );
  }

  void _setPlaying(bool value) {
    setState(() {
      // Pressing play on the last step replays from the beginning.
      if (value && _atEnd) _index = 0;
      _playing = value;
    });
    _restartTimer();
  }

  void _goTo(int index) {
    setState(() {
      _index = index.clamp(0, widget.trace.steps.length - 1);
      _playing = false;
    });
    _timer?.cancel();
  }

  void _cycleSpeed() {
    const speeds = [0.5, 1.0, 1.5, 2.0];
    setState(() {
      _speed = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    });
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trace = widget.trace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PatternHeader(trace: trace),
                const SizedBox(height: 20),

                // The visual panels for this step.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, scene) in _step.scenes.indexed) ...[
                        if (i > 0) const SizedBox(height: 22),
                        VizSceneView(
                          key: ValueKey(
                            '${scene.runtimeType}-${scene.title ?? i}',
                          ),
                          scene: scene,
                        ),
                      ],
                      if (_step.scenes.isEmpty)
                        Text(
                          'No elements left to show.',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _CaptionCard(step: _step),

                if (_step.insight != null) ...[
                  const SizedBox(height: 12),
                  _InsightCard(text: _step.insight!),
                ],

                const SizedBox(height: 16),
                _PseudocodePanel(
                  lines: trace.pseudocode,
                  highlighted: _step.codeLine,
                ),

                if (_atEnd) ...[
                  const SizedBox(height: 16),
                  _TakeawayCard(
                    trace: trace,
                    onCopyToBoard: widget.onCopyToBoard == null
                        ? null
                        : () => widget.onCopyToBoard!(trace),
                  ),
                ],
              ],
            ),
          ),
        ),
        _Controls(
          index: _index,
          total: trace.steps.length,
          playing: _playing,
          speed: _speed,
          onPlayPause: () => _setPlaying(!_playing),
          onPrev: _index > 0 ? () => _goTo(_index - 1) : null,
          onNext: _atEnd ? null : () => _goTo(_index + 1),
          onRestart: () => _goTo(0),
          onScrub: (value) => _goTo(value.round()),
          onSpeed: _cycleSpeed,
        ),
      ],
    );
  }
}

/// The complexity strings carry a full explanation after an em dash
/// ("O(n) — one pass"). Chips show only the O(...) part; the explanation
/// appears in the takeaway card at the end, where there is room to read it.
String _bigOOnly(String complexity) => complexity.split(' — ').first.trim();

class _PatternHeader extends StatelessWidget {
  final AlgorithmTrace trace;
  const _PatternHeader({required this.trace});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trace.pattern.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: scheme.primary,
                ),
              ),
            ),
            _MetaChip(
              icon: Icons.timer_outlined,
              label: 'Time ${_bigOOnly(trace.timeComplexity)}',
            ),
            _MetaChip(
              icon: Icons.sd_storage_outlined,
              label: 'Space ${_bigOOnly(trace.spaceComplexity)}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          trace.patternIdea,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 5),
          // Complexity notes are full sentences; let them wrap rather than
          // run off the edge on a phone.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  final VizStep step;
  const _CaptionCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.record_voice_over_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSize(
              duration: kVizTransition,
              curve: kVizCurve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: kVizTransition,
                child: Text(
                  step.caption,
                  key: ValueKey(step.caption),
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PseudocodePanel extends StatelessWidget {
  final List<String> lines;
  final int? highlighted;

  const _PseudocodePanel({required this.lines, this.highlighted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, line) in lines.indexed)
            AnimatedContainer(
              duration: kVizTransition,
              curve: kVizCurve,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              color: i == highlighted
                  ? scheme.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'Menlo',
                        fontFamilyFallback: const ['Courier New', 'monospace'],
                        fontSize: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.isEmpty ? ' ' : line,
                      style: TextStyle(
                        fontFamily: 'Menlo',
                        fontFamilyFallback: const ['Courier New', 'monospace'],
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: i == highlighted
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: i == highlighted
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TakeawayCard extends StatelessWidget {
  final AlgorithmTrace trace;
  final VoidCallback? onCopyToBoard;

  const _TakeawayCard({required this.trace, this.onCopyToBoard});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E9E6A).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E9E6A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 18,
                color: Color(0xFF1E9E6A),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember this',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trace.takeaway,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _ComplexityRow(
            icon: Icons.timer_outlined,
            label: 'Time',
            detail: trace.timeComplexity,
          ),
          const SizedBox(height: 6),
          _ComplexityRow(
            icon: Icons.sd_storage_outlined,
            label: 'Space',
            detail: trace.spaceComplexity,
          ),
          if (onCopyToBoard != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onCopyToBoard,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Put this on my board'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComplexityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;

  const _ComplexityRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final int index;
  final int total;
  final bool playing;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onRestart;
  final ValueChanged<double> onScrub;
  final VoidCallback onSpeed;

  const _Controls({
    required this.index,
    required this.total,
    required this.playing,
    required this.speed,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
    required this.onRestart,
    required this.onScrub,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  'Step ${index + 1}/$total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: index.toDouble(),
                    min: 0,
                    max: (total - 1).toDouble().clamp(0.0, double.infinity),
                    divisions: total > 1 ? total - 1 : null,
                    label: 'Step ${index + 1}',
                    onChanged: onScrub,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSpeed,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  '${speed == speed.roundToDouble() ? speed.toInt() : speed}x',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Prev / play / next stay truly centered; restart sits on the far
          // left rather than shifting the cluster with a filler spacer.
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Start over',
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Previous step',
                      onPressed: onPrev,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onPlayPause,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Next step',
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen host for an animation, opened from the problem list or the AI
/// panel.
class AlgorithmPlayerPage extends StatelessWidget {
  final AlgorithmTrace trace;
  final void Function(AlgorithmTrace trace)? onCopyToBoard;

  const AlgorithmPlayerPage({
    super.key,
    required this.trace,
    this.onCopyToBoard,
  });

  static Future<void> open(
    BuildContext context,
    AlgorithmTrace trace, {
    void Function(AlgorithmTrace trace)? onCopyToBoard,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AlgorithmPlayerPage(trace: trace, onCopyToBoard: onCopyToBoard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trace.title, style: const TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: SafeArea(
        child: AlgorithmPlayer(trace: trace, onCopyToBoard: onCopyToBoard),
      ),
    );
  }
}
