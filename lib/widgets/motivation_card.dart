import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../theme.dart';
import 'animated_press_button.dart';

class MotivationCard extends StatefulWidget {
  const MotivationCard({super.key});

  @override
  State<MotivationCard> createState() => _MotivationCardState();
}

class _MotivationCardState extends State<MotivationCard> with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  List<Map<String, dynamic>> _quotes = [];
  Map<String, dynamic>? _currentQuote;
  final Random _random = Random();
  bool _isLoading = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quotes.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _quotes = jsonList.map((e) => e as Map<String, dynamic>).toList();
      _pickRandomQuote();
    } catch (e) {
      debugPrint('Error loading quotes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _pickRandomQuote() {
    if (_quotes.isEmpty) return;
    _fadeCtrl.reverse().then((_) {
      setState(() {
        _currentQuote = _quotes[_random.nextInt(_quotes.length)];
      });
      _fadeCtrl.forward();
    });
  }

  Future<void> _shareQuote() async {
    HapticFeedback.mediumImpact();
    try {
      final image = await _screenshotCtrl.capture(delay: const Duration(milliseconds: 10));
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/motivation_share.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)], text: 'جرعة تفاؤل من الدحيح 👑');
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    if (_currentQuote == null) return const SizedBox();

    return Screenshot(
      controller: _screenshotCtrl,
      child: AnimatedPressButton(
        onTap: () {
          HapticFeedback.lightImpact();
          _pickRandomQuote();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: glassDecoration(radius: 24, fill: Colors.white.withValues(alpha: 0.08)),
              child: Stack(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_quote_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _currentQuote!['category'].toString().toUpperCase(),
                            style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Text(
                          _currentQuote!['text'],
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                            shadows: [
                              Shadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5), blurRadius: 12)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Dahih App – 2026', style: GoogleFonts.cairo(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
                        ],
                      )
                    ],
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white54, size: 20),
                      onPressed: _shareQuote,
                      tooltip: 'مشاركة على انستقرام',
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
