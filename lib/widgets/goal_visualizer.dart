import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Neon circular progress ring showing today's study time vs the daily goal.
class GoalVisualizer extends StatefulWidget {
  final double progress;      // 0.0–1.0
  final int todayMinutes;
  final int goalMinutes;
  final bool milestoneReached;

  const GoalVisualizer({
    super.key,
    required this.progress,
    required this.todayMinutes,
    required this.goalMinutes,
    this.milestoneReached = false,
  });

  @override
  State<GoalVisualizer> createState() => _GoalVisualizerState();
}

class _GoalVisualizerState extends State<GoalVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  String _formatMinutes(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${min}د';
    if (min == 0) return '${h}س';
    return '${h}س ${min}د';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arcColor = widget.milestoneReached ? kGold : cs.secondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: glassDecoration(
            fill: widget.milestoneReached
                ? kGold.withValues(alpha: .08)
                : kGlassFill,
            border: widget.milestoneReached
                ? kGold.withValues(alpha: .4)
                : kGlassBorder,
          ),
          child: Row(
            children: [
              // ── Neon ring ────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => SizedBox(
                  width: 84,
                  height: 84,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: widget.progress,
                      color: arcColor,
                      glow: _glowAnim.value *
                          (widget.milestoneReached ? 1.4 : 1.0),
                    ),
                    child: Center(
                      child: Text(
                        '${(widget.progress * 100).round()}%',
                        style: GoogleFonts.tajawal(
                          color: arcColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── Labels ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.milestoneReached ? '🏆 إنجاز!' : 'هدف اليوم',
                      style: GoogleFonts.tajawal(
                        color: widget.milestoneReached
                            ? kGold
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatMinutes(widget.todayMinutes),
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: '  /  ${_formatMinutes(widget.goalMinutes)}',
                            style: GoogleFonts.cairo(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(arcColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ring painter ───────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glow;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 8;

    // Track
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    if (progress <= 0) return;

    // Neon filled arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * glow),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.glow != glow;
}
