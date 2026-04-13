import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/subject_model.dart';
import '../theme.dart';
import 'ocr_notes_page.dart';

/// Spaced Repetition Logic helper
bool _needsReview(Unit u) {
  if (u.nextReviewDate == null) return false;
  return DateTime.now().isAfter(u.nextReviewDate!);
}

Future<void> _scheduleSpacedRepetition(Unit u, SubjectStore store) async {
  // simple SR algorithm: if studied, review in 1 day; if reviewed, review in 3 days; if solved, review in 7 days.
  int daysToAdd = 1;
  if (u.isSolved) daysToAdd = 7;
  else if (u.isReviewed) daysToAdd = 3;

  u.nextReviewDate = DateTime.now().add(Duration(days: daysToAdd));
  await store.persist();
}

class SubjectDetailPage extends StatefulWidget {
  final SubjectStore store;
  final String subjectId;

  const SubjectDetailPage({super.key, required this.store, required this.subjectId});

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  final _unitCtrl = TextEditingController();

  Subject get _subject => widget.store.subjects.firstWhere((s) => s.id == widget.subjectId);

  void _addUnit() async {
    final title = _unitCtrl.text.trim();
    if (title.isNotEmpty) {
      await widget.store.addUnit(_subject.id, title);
      _unitCtrl.clear();
      HapticFeedback.lightImpact();
      setState((){});
    }
  }

  void _toggleCheckbox(Unit u, int index) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (index == 0) { u.isStudied = !u.isStudied; }
      if (index == 1) { u.isReviewed = !u.isReviewed; }
      if (index == 2) { u.isSolved = !u.isSolved; }
    });
    // Schedule next review based on interaction
    await _scheduleSpacedRepetition(u, widget.store);
  }

  Widget _buildCheck(Unit u, int index, String label, bool value) {
    return GestureDetector(
      onTap: () => _toggleCheckbox(u, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? _subject.color.withValues(alpha: .2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? _subject.color : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value ? Icons.check_circle : Icons.circle_outlined,
                size: 16, color: value ? _subject.color : Colors.white54),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.cairo(color: value ? Colors.white : Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _subject;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.name, style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(s.isArchived ? Icons.unarchive : Icons.archive),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await widget.store.toggleArchive(s.id);
              if (!mounted) return;
              setState((){});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArchived ? 'تمت الأرشفة بنجاح' : 'تم استعادة المادة')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => OcrNotesPage(subjectId: s.id, subjectName: s.name)
              ));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Header Progress
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: glassDecoration(
              fill: s.color.withValues(alpha: .1),
              border: s.color.withValues(alpha: .3),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: s.progress, color: s.color, backgroundColor: Colors.white12, strokeWidth: 6)),
                    Text('${(s.progress * 100).round()}%', style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, color: s.color)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('جاهزية المادة', style: GoogleFonts.tajawal(color: Colors.white70)),
                      Text(s.category, style: GoogleFonts.cairo(color: s.color, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Add Unit Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    style: GoogleFonts.cairo(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'إضافة وحدة أو درس جديد...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addUnit,
                  icon: const Icon(Icons.add_circle, size: 36),
                  color: s.color,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Units List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: s.units.length,
              itemBuilder: (context, i) {
                final u = s.units[i];
                final reviewDue = _needsReview(u);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: glassDecoration(
                    // Orange tint if Spaced Repetition engine flags it for review
                    border: reviewDue ? Colors.orangeAccent.withValues(alpha: .5) : Colors.white12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(u.title, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (reviewDue) const Icon(Icons.notification_important, color: Colors.orangeAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildCheck(u, 0, 'درستها', u.isStudied),
                          _buildCheck(u, 1, 'راجعته', u.isReviewed),
                          _buildCheck(u, 2, 'حليت وزاري', u.isSolved),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
