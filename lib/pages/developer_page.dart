import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/animated_press_button.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> with TickerProviderStateMixin {
  // Staggered Animations
  late AnimationController _staggerCtrl;
  late Animation<double> _nameFade;
  late Animation<Offset> _nameSlide;
  late Animation<double> _badgeFade;
  late Animation<double> _cardFade;

  // Values pulsers
  final List<AnimationController> _valueCtrls = [];

  final List<Map<String, dynamic>> _coreValues = [
    {'title': 'Precision', 'icon': Icons.track_changes_rounded},
    {'title': 'Innovation', 'icon': Icons.lightbulb_outline_rounded},
    {'title': 'Student-First', 'icon': Icons.school_outlined},
    {'title': 'Jordanian Pride', 'icon': Icons.flag_circle_outlined},
  ];

  // Shader
  ui.FragmentShader? _shader;
  late Ticker _ticker;
  double _time = 0.0;
  Offset _touch = Offset(-1.0, -1.0); // Default off-screen

  @override
  void initState() {
    super.initState();
    _loadShader();

    // Shader Ticker (120FPS locked fluid animation)
    _ticker = createTicker((elapsed) {
      if (_shader != null) {
        setState(() {
          _time = elapsed.inMicroseconds / 1000000.0 * 1.5; // Speed multiplier
        });
      }
    })..start();

    // Staggered Entry
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    _nameFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.2, 0.4, curve: Curves.easeOut));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.2, 0.4, curve: Curves.easeOutBack)));

    _badgeFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.4, 0.6, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.6, 0.8, curve: Curves.easeOut));

    for (int i = 0; i < _coreValues.length; i++) {
      _valueCtrls.add(AnimationController(vsync: this, lowerBound: 0.8, upperBound: 1.2, duration: const Duration(milliseconds: 300)));
    }

    _staggerCtrl.forward();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('assets/shaders/aurora.frag');
      setState(() {
        _shader = program.fragmentShader();
      });
    } catch (e) {
      debugPrint('Shader failed to load: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _staggerCtrl.dispose();
    for (var ctrl in _valueCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _pulseValue(int index) {
    HapticFeedback.lightImpact();
    _valueCtrls[index].forward().then((_) => _valueCtrls[index].reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('The Architect', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _touch = details.localPosition);
        },
        onPanEnd: (_) {
          setState(() => _touch = const Offset(-1.0, -1.0)); // Reset offscreen
        },
        onTapDown: (details) {
          setState(() => _touch = details.localPosition);
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) => setState(() => _touch = const Offset(-1.0, -1.0)),
        child: Stack(
          children: [
            // Shader Background
            if (_shader != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _AuroraPainter(_shader!, _time, _touch),
                ),
              )
            else
              // Fallback deep blue background if shader fails to load yet
              Container(color: const Color(0xFF0D1B2A)),

            // H.Y.A Watermark
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WatermarkPainter(),
                ),
              ),
            ),

            // Glassmorphism Overlay (for depth above the raw fluid)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Signature Reveal
                    SlideTransition(
                      position: _nameSlide,
                      child: FadeTransition(
                        opacity: _nameFade,
                        child: Column(
                          children: [
                            Text(
                              'Hazem Yosef Ababneh',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(blurRadius: 20, color: const Color(0xFFE0A96D).withValues(alpha: 0.6))
                                ]
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lead Architect & Visionary behind Dahih App',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verified Developer Badge
                    FadeTransition(
                      opacity: _badgeFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0A96D).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFE0A96D).withValues(alpha: 0.5), width: 1),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFE0A96D).withValues(alpha: 0.2), blurRadius: 16)
                          ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFFE0A96D), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'VERIFIED DEVELOPER',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFE0A96D),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Floating Card
                    FadeTransition(
                      opacity: _cardFade,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: glassDecoration(radius: 24, fill: Colors.white.withValues(alpha: 0.05)),
                            child: Column(
                              children: [
                                Text(
                                  'Crafted with passion in Jordan to empower every Tawjihi student to reach their peak.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Core Values
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(_coreValues.length, (index) {
                                    final val = _coreValues[index];
                                    return GestureDetector(
                                      onTap: () => _pulseValue(index),
                                      child: ScaleTransition(
                                        scale: _valueCtrls[index],
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withValues(alpha: 0.1),
                                              ),
                                              child: Icon(val['icon'], color: Colors.white, size: 24),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              val['title'],
                                              style: GoogleFonts.cairo(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Footer & Contact
                    AnimatedPressButton(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Contacting Hazem Yosef Ababneh...', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFF0D1B2A),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 20)
                          ]
                        ),
                        child: Text(
                          'CONTACT THE CREATOR',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF0D1B2A),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      '© 2026 | All Rights Reserved to Hazem Yosef Ababneh',
                      style: GoogleFonts.cairo(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Custom GLSL Shader Painter
class _AuroraPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Offset touch;

  _AuroraPainter(this.shader, this.time, this.touch);

  @override
  void paint(Canvas canvas, Size size) {
    // Uniforms mapping based on exactly how they appear in the .frag file:
    // u_resolution, u_time, u_touch
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, touch.dx);
    shader.setFloat(4, touch.dy);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.touch != touch;
  }
}

// Subtle H.Y.A Watermark
class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'H.Y.A',
        style: GoogleFonts.playfairDisplay(
          fontSize: size.width * 0.4,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.03),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    
    canvas.save();
    // Rotate slightly and center
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
