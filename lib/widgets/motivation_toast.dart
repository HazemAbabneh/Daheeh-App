import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Subliminal fast-fading motivation toast.
/// Auto-dismisses after [duration]. Shows as an overlay above everything.
class MotivationToast {
  static OverlayEntry? _current;

  static const _messages = [
    'أنت أقوى مما تظن 💪',
    'لن يُضيَّع جهد صادق',
    'كل دقيقة تُحتسب ✨',
    'تفوّق على أمس',
    'العقل سلاحك الأقوى 🧠',
    'استمر، المجد قريب',
    'التوجيهي لك وحدك',
    'ركّز، أنت في المنطقة 🔥',
    'لا توجد أعذار الآن',
    'اصنع مستقبلك الآن',
  ];

  static final _rng = Random();

  /// Show a random subliminal toast. Safe to call multiple times.
  static void show(BuildContext context, {Duration duration = const Duration(seconds: 2)}) {
    _current?.remove();
    _current = null;

    final msg = _messages[_rng.nextInt(_messages.length)];
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(message: msg, duration: duration),
    );
    _current = entry;

    Overlay.of(context).insert(entry);
    Future.delayed(duration + const Duration(milliseconds: 500), () {
      entry.remove();
      if (_current == entry) _current = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  const _ToastWidget({required this.message, required this.duration});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _opacityAnim,
          child: Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _ctrl.reverse();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x667C3AED),
                      blurRadius: 24,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Text(
                  widget.message,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
