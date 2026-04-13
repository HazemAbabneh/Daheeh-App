import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GitHub-style activity heatmap showing daily study intensity over the
/// past [weeks] weeks (default: 8 weeks).
class ActivityHeatmap extends StatelessWidget {
  /// entries[i] = MapEntry(dateString, minutes)  oldest → newest
  final List<MapEntry<String, int>> entries;

  /// Minutes at which we consider a cell "fully saturated" in color.
  final int maxMinutes;

  const ActivityHeatmap({
    super.key,
    required this.entries,
    this.maxMinutes = 120,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const cellSize  = 13.0;
    const cellGap   = 3.0;
    const cols      = 56; // 8 weeks × 7 days
    final display   = entries.length > cols ? entries.sublist(entries.length - cols) : entries;

    // Pad at the front so we always render [cols] cells
    final padded = [
      ...List.generate(cols - display.length,
              (_) => const MapEntry('', 0)),
      ...display,
    ];

    // Organise into 7-row columns (Mon–Sun)
    final weeks = <List<MapEntry<String, int>>>[];
    for (var col = 0; col < cols; col += 7) {
      weeks.add(padded.sublist(col, (col + 7).clamp(0, padded.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'سجل الدراسة — ٨ أسابيع',
            style: GoogleFonts.tajawal(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: weeks.map((week) {
            return Column(
              children: week.map((entry) {
                return _HeatCell(
                  minutes:    entry.value,
                  maxMinutes: maxMinutes,
                  accent:     cs.secondary,
                  size:       cellSize,
                  gap:        cellGap,
                  dateLabel:  entry.key,
                );
              }).toList(),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('أقل', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11)),
            const SizedBox(width: 6),
            for (final frac in [0.05, 0.25, 0.5, 0.75, 1.0])
              Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.only(left: cellGap),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _cellColor(frac, cs.secondary),
                ),
              ),
            const SizedBox(width: 6),
            Text('أكثر', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static Color _cellColor(double frac, Color accent) {
    if (frac <= 0) return Colors.white.withValues(alpha: .05);
    return Color.lerp(
      accent.withValues(alpha: .15),
      accent,
      frac,
    )!;
  }
}

class _HeatCell extends StatelessWidget {
  final int    minutes;
  final int    maxMinutes;
  final Color  accent;
  final double size;
  final double gap;
  final String dateLabel;

  const _HeatCell({
    required this.minutes,
    required this.maxMinutes,
    required this.accent,
    required this.size,
    required this.gap,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final frac = maxMinutes > 0
        ? (minutes / maxMinutes).clamp(0.0, 1.0)
        : 0.0;
    final color = ActivityHeatmap._cellColor(frac, accent);

    return Tooltip(
      message: dateLabel.isEmpty ? '' : '$dateLabel\n${minutes}د',
      child: Container(
        width:  size,
        height: size,
        margin: EdgeInsets.only(bottom: gap, right: gap),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: color,
          boxShadow: minutes > 0
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: frac * 0.5),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
