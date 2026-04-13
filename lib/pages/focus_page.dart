import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quotes.dart';
import '../theme.dart';

/// Full-screen Focus Mode page.
/// Reached via a Hero transition from the timer arc in HomePage.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  static const heroTag = 'pomodoro_arc';

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;
  String _quote = randomQuote();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _newQuote() async {
    setState(() => _quote = randomQuote());
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: kBgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: kGlassFill,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow backdrop
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: _pulseAnim.value * 0.9,
                  colors: [
                    cs.primary.withValues(alpha: .25),
                    kBgDark,
                  ],
                ),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              // ── Hero arc ──────────────────────────────────────────────────
              Hero(
                tag: FocusPage.heroTag,
                flightShuttleBuilder: _flightShuttle,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: MediaQuery.of(context).size.width * 0.78,
                    child: _FocusArc(glowScale: _pulseAnim.value),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Mode label ────────────────────────────────────────────────
              Text(
                'وضع التركيز العميق',
                style: GoogleFonts.tajawal(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 40),

              // ── Quote ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: _newQuote,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: glassDecoration(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.format_quote_rounded,
                                color: cs.secondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _quote,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  height: 1.7,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'اضغط على الاقتباس لتغييره',
                style: GoogleFonts.cairo(
                    color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flightShuttle(
    BuildContext ctx,
    Animation<double> anim,
    HeroFlightDirection dir,
    BuildContext from,
    BuildContext to,
  ) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => _FocusArc(glowScale: anim.value),
    );
  }
}

// ── Standalone arc for Hero target/source ─────────────────────────────────────
class _FocusArc extends StatelessWidget {
  final double glowScale;
  const _FocusArc({this.glowScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _FocusArcPainter(
        primary:   cs.primary,
        secondary: cs.secondary,
        glow:      glowScale,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '◉',
              style: TextStyle(
                fontSize: 28,
                color: cs.secondary.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ركّز',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusArcPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final double glow;

  const _FocusArcPainter({
    required this.primary,
    required this.secondary,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 16;

    // Track ring
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // Neon sweep
    final shader = SweepGradient(
      colors:  [primary, secondary, primary],
      stops:   const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * 0.72,
      false,
      Paint()
        ..shader   = shader
        ..style    = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap  = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * glow),
    );
  }

  @override
  bool shouldRepaint(_FocusArcPainter old) => old.glow != glow;
}
