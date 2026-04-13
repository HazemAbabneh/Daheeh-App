import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Golden full-screen celebration overlay that appears after 4+ hours of study.
/// Call [MilestoneOverlay.show(context)] to display it.
class MilestoneOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const MilestoneOverlay({super.key, required this.onDismiss});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      builder: (_) => MilestoneOverlay(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 6))
      ..play();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.elasticOut),
    );

    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Confetti burst ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [kGold, Colors.white, Color(0xFF7C3AED), Color(0xFF22D3EE)],
                numberOfParticles: 40,
                gravity: 0.12,
                emissionFrequency: 0.04,
                maxBlastForce: 20,
                minBlastForce: 5,
              ),
            ),
          ),

          // ── Card ──────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: glassDecoration(
                    fill:   kGold.withValues(alpha: .12),
                    border: kGold.withValues(alpha: .6),
                    shadows: [
                      BoxShadow(
                        color: kGold.withValues(alpha: .35),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [kGold, Colors.white, kGold],
                        ).createShader(r),
                        child: Text(
                          '🏆',
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'إنجاز أسطوري!',
                        style: GoogleFonts.tajawal(
                          color: kGold,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '٤ ساعات متواصلة من الدراسة!\n'
                        'أنت من أقوى طلاب التوجيهي.\n'
                        'استرح قليلاً، تستحق ذلك.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onDismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kGold, Color(0xFFFFF3B0)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: kGold.withValues(alpha: .5),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: Text(
                            'شكراً، سأكمل غداً',
                            style: GoogleFonts.tajawal(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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
