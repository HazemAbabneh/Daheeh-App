
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/animated_press_button.dart';

/// Phase 3 OCR feature: Taking photos of notes and extracting text.
class OcrNotesPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  const OcrNotesPage({super.key, required this.subjectId, required this.subjectName});

  @override
  State<OcrNotesPage> createState() => _OcrNotesPageState();
}

class _OcrNotesPageState extends State<OcrNotesPage> {
  bool _isProcessing = false;
  List<String> _notes = [];
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notes = prefs.getStringList('dahih_notes_${widget.subjectId}') ?? [];
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dahih_notes_${widget.subjectId}', _notes);
  }

  Future<void> _scanNote() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

      if (recognizedText.text.trim().isNotEmpty) {
        setState(() {
          _notes.insert(0, recognizedText.text);
        });
        await _saveNotes();
        HapticFeedback.heavyImpact();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على نص واضح في الصورة.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('حدث خطأ أثناء المسح: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ملاحظات ذكية - ${widget.subjectName}',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: _notes.isEmpty
          ? Center(
              child: Text(
                'لا توجد ملاحظات. مسح اللوح أو الدفتر باستخدام الكاميرا.',
                style: GoogleFonts.cairo(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: glassDecoration(),
                child: SelectableText(
                  _notes[i],
                  style: GoogleFonts.cairo(color: Colors.white, height: 1.6),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
      floatingActionButton: AnimatedPressButton(
        onTap: _isProcessing ? null : _scanNote,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: .4),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: _isProcessing
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.document_scanner, color: Colors.white),
        ),
      ),
    );
  }
}
