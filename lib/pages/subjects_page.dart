import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/subject_model.dart';
import '../theme.dart';
import 'subject_detail_page.dart';
import 'grade_simulator_page.dart';
import '../widgets/animated_press_button.dart';

class SubjectsPage extends StatefulWidget {
  final SubjectStore store;
  const SubjectsPage({super.key, required this.store});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    String category = 'علمي';
    final categories = ['علمي', 'أدبي', 'مشترك', 'مهارات'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x33FFFFFF))),
          title: Text('إضافة مبحث', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.cairo(color: Colors.white),
                decoration: const InputDecoration(labelText: 'اسم المبحث', hintText: 'مثال: فيزياء...'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: const Color(0xFF1A1A2E),
                style: GoogleFonts.cairo(color: Colors.white),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setD(() => category = v!),
                decoration: const InputDecoration(labelText: 'التصنيف'),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await widget.store.add(name, category);
                HapticFeedback.lightImpact();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Subject s) {
    final pct = (s.progress * 100).round();
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
      ),
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        await widget.store.remove(s.id);
      },
      child: AnimatedPressButton(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailPage(store: widget.store, subjectId: s.id)));
        },
        child: Hero(
          tag: 'subject_card_${s.id}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: glassDecoration(fill: s.isArchived ? Colors.grey.withValues(alpha: 0.05) : kGlassFill),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: s.color.withValues(alpha: .6), blurRadius: 8)]),
                              ),
                              const SizedBox(width: 10),
                              Text(s.name, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: s.color.withValues(alpha: .2), borderRadius: BorderRadius.circular(30)),
                            child: Text('$pct%', style: GoogleFonts.tajawal(color: s.color, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.progress,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(s.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final active = widget.store.activeSubjects;
        final archived = widget.store.archivedSubjects;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('مواد التوجيهي', style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 24)),
            actions: [
              IconButton(
                icon: const Icon(Icons.calculate_rounded),
                tooltip: 'محاكي المعدل',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GradeSimulatorPage())),
              )
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: 'الحالية'), Tab(text: 'المؤرشفة')],
            ),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              active.isEmpty
                  ? Center(child: Text('لا توجد مواد دراسية نشطة', style: GoogleFonts.cairo(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: active.length,
                      itemBuilder: (_, i) => _buildCard(active[i]),
                    ),
              archived.isEmpty
                  ? Center(child: Text('لا توجد مواد مؤرشفة', style: GoogleFonts.cairo(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: archived.length,
                      itemBuilder: (_, i) => _buildCard(archived[i]),
                    ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('إضافة مادة', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        );
      },
    );
  }
}

