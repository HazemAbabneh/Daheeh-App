import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Phase 3: "Anti-Panic" Exam Breathing Exercise (4-7-8 method).
class BreathingModule extends StatefulWidget {
  const BreathingModule({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreathingModule(),
    );
  }

  @override
  State<BreathingModule> createState() => _BreathingModuleState();
}

class _BreathingModuleState extends State<BreathingModule>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  String _instruction = "جاهز؟";
  Color _color = const Color(0xFF22D3EE);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
    _runCycle();
  }

  Future<void> _runCycle() async {
    while (mounted) {
      // Inhale 4s
      setState(() {
        _instruction = "شهيق...";
        _color = const Color(0xFF22D3EE); // Cyan
      });
      HapticFeedback.lightImpact();
      _ctrl.duration = const Duration(seconds: 4);
      await _ctrl.forward();
      if (!mounted) return;

      // Hold 7s
      setState(() {
        _instruction = "احبس تنفسك";
        _color = const Color(0xFF10B981); // Emerald
      });
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(seconds: 7));
      if (!mounted) return;

      // Exhale 8s
      setState(() {
        _instruction = "زفير ببطء...";
        _color = const Color(0xFF7C3AED); // Violet
      });
      HapticFeedback.mediumImpact();
      _ctrl.duration = const Duration(seconds: 8);
      await _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF10102A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تمرين تنفس 8-7-4',
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لمقاومة توتر الامتحانات لاستعادة صفاؤك الذهني',
            style: GoogleFonts.cairo(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 60),
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, __) => Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color.withValues(alpha: .15 * _scaleAnim.value + 0.05),
                border: Border.all(
                  color: _color.withValues(alpha: _scaleAnim.value),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: .3 * _scaleAnim.value),
                    blurRadius: 40,
                    spreadRadius: 10 * _scaleAnim.value,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: 0.5 + 0.5 * _scaleAnim.value,
                child: Center(
                  child: Text(
                    _instruction,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
