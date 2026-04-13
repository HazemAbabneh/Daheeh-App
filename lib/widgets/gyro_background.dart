import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GyroBackground extends StatefulWidget {
  final Widget child;
  final List<Color> accentColors;

  const GyroBackground({
    super.key,
    required this.child,
    required this.accentColors,
  });

  @override
  State<GyroBackground> createState() => _GyroBackgroundState();
}

class _GyroBackgroundState extends State<GyroBackground>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _tiltX = 0;
  double _tiltY = 0;
  late final List<_Particle> _particles;
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(45, (_) => _Particle.random());
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Gyroscope — silently skip if unavailable (emulator / iOS simulator)
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(
      (e) {
        if (!mounted) return;
        setState(() {
          _tiltX = (_tiltX + e.y * 0.8).clamp(-28.0, 28.0);
          _tiltY = (_tiltY + e.x * 0.8).clamp(-28.0, 28.0);
        });
      },
      onError: (_) {/* device has no gyro – silently ignore */},
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _drift,
          builder: (_, __) => RepaintBoundary(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _drift.value,
                tiltX: _tiltX,
                tiltY: _tiltY,
                colors: widget.accentColors,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ── Particle data class ────────────────────────────────────────────────────────
class _Particle {
  final double x;       // 0.0–1.0 base position
  final double y;
  final double size;    // radius in logical pixels
  final double speed;   // drift speed multiplier
  final double phase;   // animation phase offset
  final int colorIdx;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.colorIdx,
  });

  factory _Particle.random() {
    final r = math.Random();
    return _Particle(
      x:        r.nextDouble(),
      y:        r.nextDouble(),
      size:     r.nextDouble() * 4 + 1.5,
      speed:    r.nextDouble() * 0.25 + 0.08,
      phase:    r.nextDouble() * 2 * math.pi,
      colorIdx: r.nextInt(4),
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double tiltX;
  final double tiltY;
  final List<Color> colors;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.tiltX,
    required this.tiltY,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    for (final p in particles) {
      // Drift upward slowly, wrapping at top
      final t = (progress * p.speed + p.phase / (2 * math.pi)) % 1.0;
      final rawY = (p.y - t) % 1.0;

      // Parallax shift from gyro (deeper particles move less)
      final parallaxScale = p.size / 6.0;
      final px = (p.x + tiltX / size.width  * parallaxScale * 8) * size.width;
      final py = (rawY + tiltY / size.height * parallaxScale * 8) * size.height;

      final color = colors[p.colorIdx % colors.length]
          .withValues(alpha: 0.18 + 0.12 * math.sin(t * math.pi));

      canvas.drawCircle(
        Offset(px, py),
        p.size,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.4),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.tiltX != tiltX || old.tiltY != tiltY;
}
