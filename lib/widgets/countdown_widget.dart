import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Live countdown to Ministry Exams (Phase 3 & 5 "Final Boss" element).
class CountdownWidget extends StatefulWidget {
  final DateTime examDate;
  const CountdownWidget({super.key, required this.examDate});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calc());
  }

  void _calc() {
    final now = DateTime.now();
    setState(() {
      _diff = widget.examDate.isAfter(now) ? widget.examDate.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _buildBlock(String label, int value) {
    // Redder output as it gets closer (Final Boss UI shift)
    final cs = Theme.of(context).colorScheme;
    final isCritical = _diff.inDays < 30;
    final color = isCritical ? const Color(0xFFEF4444) : cs.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_diff.inSeconds <= 0) return const SizedBox.shrink();

    final isCritical = _diff.inDays < 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFEF4444).withValues(alpha: .1) : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical ? const Color(0xFFEF4444).withValues(alpha: .3) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBlock('ثانية', _diff.inSeconds % 60),
          _buildBlock('دقيقة', _diff.inMinutes % 60),
          _buildBlock('ساعة', _diff.inHours % 24),
          _buildBlock('يوم', _diff.inDays),
        ],
      ),
    );
  }
}
