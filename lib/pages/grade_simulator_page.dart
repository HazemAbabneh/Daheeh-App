import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';


/// Interactive calculator for Jordanian Tawjihi Grade (out of 100).
class GradeSimulatorPage extends StatefulWidget {
  const GradeSimulatorPage({super.key});

  @override
  State<GradeSimulatorPage> createState() => _GradeSimulatorPageState();
}

class _GradeSimulatorPageState extends State<GradeSimulatorPage> {
  final Map<String, double> _grades = {
    'الرياضيات': 200,
    'اللغة العربية': 200,
    'اللغة الإنجليزية': 200,
    'التربية الإسلامية': 200,
    'تاريخ الأردن': 200,
    'الفيزياء (أو تخصص 1)': 200,
    'الكيمياء (أو تخصص 2)': 200,
  };

  double get _totalPercentage {
    final sum = _grades.values.fold(0.0, (a, b) => a + b);
    return sum / (_grades.length * 200) * 100;
  }

  Widget _buildSlider(String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_grades[subject]!.round()} / 200',
                style: GoogleFonts.cairo(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
            ),
            child: Slider(
              value: _grades[subject]!,
              min: 0,
              max: 200,
              divisions: 200,
              onChanged: (val) {
                setState(() => _grades[subject] = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTop = _totalPercentage >= 90;
    final color = isTop ? kGold : Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'محاكي المعدل',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0B19),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Result Card
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: glassDecoration(
                  fill: color.withValues(alpha: .1),
                  border: color.withValues(alpha: .4),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'المعدل المتوقع',
                        style: GoogleFonts.cairo(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_totalPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.tajawal(
                          color: color,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: color.withValues(alpha: .5), blurRadius: 20),
                          ],
                        ),
                      ),
                      if (isTop)
                        Text(
                          '🔥 ممتاز! واصل الإبداع',
                          style: GoogleFonts.tajawal(color: kGold, fontWeight: FontWeight.bold),
                        )
                    ],
                  ),
                ),
              ),

              // Sliders List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  children: _grades.keys.map(_buildSlider).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
