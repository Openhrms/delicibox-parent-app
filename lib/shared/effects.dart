import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Colorful floating message (toast-style).
void showNiceSnack(BuildContext context, String message,
    {IconData icon = Icons.check_circle, Color? color}) {
  final c = color ?? Theme.of(context).colorScheme.primary;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.withOpacity(.95), c.withOpacity(.75)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: c.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    ),
  );
}

/// Confetti overlay with custom palette.
class SmallConfetti extends StatefulWidget {
  final bool play;
  final Alignment alignment;
  final List<Color>? colors;
  const SmallConfetti({super.key, required this.play, this.alignment = Alignment.topCenter, this.colors});

  @override
  State<SmallConfetti> createState() => _SmallConfettiState();
}
class _SmallConfettiState extends State<SmallConfetti> {
  late final ConfettiController _c = ConfettiController(duration: const Duration(milliseconds: 700));
  @override
  void didUpdateWidget(covariant SmallConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playing = _c.state == ConfettiControllerState.playing;
    if (widget.play && !playing) _c.play();
    if (!widget.play && playing) _c.stop();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final palette = widget.colors ??
        const [Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFFFFB74D), Color(0xFF29B6F6), Color(0xFF66BB6A)];
    return Align(
      alignment: widget.alignment,
      child: ConfettiWidget(
        confettiController: _c,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 18,
        maxBlastForce: 18, minBlastForce: 6, emissionFrequency: 0.9,
        colors: palette,
      ),
    );
  }
}

/// Cute emoji pop animation.
class EmojiBurst extends StatefulWidget {
  final bool play;
  final String emoji;
  const EmojiBurst({super.key, required this.play, required this.emoji});
  @override
  State<EmojiBurst> createState() => _EmojiBurstState();
}
class _EmojiBurstState extends State<EmojiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  @override
  void didUpdateWidget(covariant EmojiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !_a.isAnimating) _a.forward(from: 0);
  }
  @override
  void dispose() { _a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _a,
          builder: (_, __) {
            final t = Curves.easeOutBack.transform(_a.value);
            double opacity;
            if (_a.value < .8) {
              opacity = 1.0;
            } else {
              // clamp returns num -> cast to double
              opacity = (1 - (_a.value - .8) / .2).clamp(0.0, 1.0) as double;
            }
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.6 + 0.8 * t,
                child: Text(widget.emoji, style: const TextStyle(fontSize: 64)),
              ),
            );
          },
        ),
      ),
    );
  }
}
