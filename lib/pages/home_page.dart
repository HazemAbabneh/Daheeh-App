import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/developer_page.dart';
import '../pages/focus_page.dart';
import '../services/ambient_audio_service.dart';
import '../services/session_store.dart';
import '../theme.dart';
import '../widgets/animated_press_button.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/goal_visualizer.dart';
import '../widgets/milestone_overlay.dart';
import '../widgets/motivation_card.dart';
import '../widgets/motivation_toast.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final SessionStore sessionStore;
  final AmbientAudioService ambientSvc;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.sessionStore,
    required this.ambientSvc,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ── Pomodoro ───────────────────────────────────────────────────────────────
  static const int _pomodoroMinutes = 25;
  late AnimationController _timerCtrl;
  bool _isRunning = false;
  Timer? _tickTimer;      // 1-second haptic tick + session accounting
  Timer? _minuteTimer;    // adds 1 minute to SessionStore every 60 s
  int   _secondsElapsed = 0;
  bool  _milestoneShown = false;

  // ── Audio ──────────────────────────────────────────────────────────────────
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // ── Tasks ──────────────────────────────────────────────────────────────────
  final List<String> _tasks = [];
  final TextEditingController _taskCtrl = TextEditingController();

  // ── Glow animations ────────────────────────────────────────────────────────
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  void initState() {
    super.initState();

    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(minutes: _pomodoroMinutes),
    )..addStatusListener(_onTimerStatus);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // AI Voice Prompt on Load (Phase 5)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && widget.sessionStore.totalXp > 0) {
        // Here we simulate the AI voice via haptics and a toast, or a generic placeholder audio.
        _sfxPlayer.play(AssetSource('sounds/task_added.wav')); 
      }
    });
  }

  // ── Timer lifecycle ────────────────────────────────────────────────────────
  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _stopTicking();
      _manageDnd(false);
      _sfxPlayer.play(AssetSource('sounds/pomodoro_end.wav'));
      HapticFeedback.vibrate();
      setState(() => _isRunning = false);
      widget.sessionStore.breakContinuity();
      _checkMilestone();
    }
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _minuteTimer?.cancel();

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) return;
      HapticFeedback.selectionClick();
      _secondsElapsed++;
      // Show subliminal toast every 5 minutes
      if (_secondsElapsed % 300 == 0 && mounted) {
        MotivationToast.show(context);
      }
    });

    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!mounted || !_isRunning) return;
      await widget.sessionStore.addMinute();
      _checkMilestone();
    });
  }

  void _stopTicking() {
    _tickTimer?.cancel();
    _minuteTimer?.cancel();
    _tickTimer = null;
    _minuteTimer = null;
  }

  void _checkMilestone() {
    if (!_milestoneShown &&
        widget.sessionStore.milestoneReached &&
        mounted) {
      _milestoneShown = true;
      MilestoneOverlay.show(context);
    }
  }

  // ── DND ────────────────────────────────────────────────────────────────────
  Future<void> _manageDnd(bool enable) async {
    bool? isGranted = await FlutterDnd.isNotificationPolicyAccessGranted;
    if (isGranted == true) {
      await FlutterDnd.setInterruptionFilter(
        enable ? FlutterDnd.INTERRUPTION_FILTER_NONE : FlutterDnd.INTERRUPTION_FILTER_ALL,
      );
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void _start() async {
    if (_isRunning) return;
    
    // Check DND permission first when user explicitly clicks play
    bool? isGranted = await FlutterDnd.isNotificationPolicyAccessGranted;
    if (!mounted) return;
    if (isGranted == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قم بتفعيل إذن (عدم الإزعاج) لتركيز أفضل')),
      );
      FlutterDnd.gotoPolicySettings();
    } else {
      _manageDnd(true);
    }

    HapticFeedback.mediumImpact();
    _timerCtrl.forward(from: _timerCtrl.value);
    setState(() => _isRunning = true);
    _startTicking();
  }

  void _pause() {
    if (!_isRunning) return;
    HapticFeedback.lightImpact();
    _timerCtrl.stop();
    _stopTicking();
    _manageDnd(false);
    widget.sessionStore.breakContinuity();
    setState(() => _isRunning = false);
  }

  void _reset() {
    HapticFeedback.heavyImpact();
    _timerCtrl.reset();
    _stopTicking();
    _manageDnd(false);
    _secondsElapsed = 0;
    widget.sessionStore.breakContinuity();
    setState(() {
      _isRunning = false;
      _milestoneShown = false;
    });
  }

  // ── Tasks ──────────────────────────────────────────────────────────────────
  void _addTask(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _sfxPlayer.play(AssetSource('sounds/task_added.wav'));
    setState(() => _tasks.add(text.trim()));
    _taskCtrl.clear();
  }

  void _removeTask(int index) {
    HapticFeedback.mediumImpact();
    _sfxPlayer.play(AssetSource('sounds/task_removed.wav'));
    setState(() => _tasks.removeAt(index));
  }

  // ── Format ─────────────────────────────────────────────────────────────────
  String _formatTime() {
    final total = (_pomodoroMinutes * 60 * (1 - _timerCtrl.value)).ceil();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _glowCtrl.dispose();
    _taskCtrl.dispose();
    _sfxPlayer.dispose();
    _stopTicking();
    super.dispose();
  }

  // ── Hero Timer card ────────────────────────────────────────────────────────
  Widget _buildTimerCard() {
    final cs = Theme.of(context).colorScheme;
    return AnimatedPressButton(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const FocusPage(),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),
      child: Hero(
        tag: FocusPage.heroTag,
        child: AnimatedBuilder(
          animation: Listenable.merge([_timerCtrl, _glowCtrl]),
          builder: (_, __) {
            final progress = _timerCtrl.value;
            final glow     = _glowAnim.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 260,
                  decoration: glassDecoration(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow behind arc
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: .28 * glow),
                              blurRadius: 80,
                              spreadRadius: 36,
                            ),
                          ],
                        ),
                      ),
                      // Arc
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(
                          painter: _ArcPainter(
                            progress:      progress,
                            glowIntensity: _isRunning ? glow : 0.35,
                            primary:   cs.primary,
                            secondary: cs.secondary,
                          ),
                        ),
                      ),
                      // Time + hint
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(),
                            style: GoogleFonts.tajawal(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isRunning ? 'اضغط للتركيز الكامل ←' : 'بوميدورو',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CtrlBtn(icon: Icons.play_arrow_rounded, label: 'ابدأ',
            color: const Color(0xFF10B981), onTap: _start, active: !_isRunning),
        _CtrlBtn(icon: Icons.pause_rounded,       label: 'وقفة',
            color: const Color(0xFFF59E0B), onTap: _pause, active: _isRunning),
        _CtrlBtn(icon: Icons.refresh_rounded,     label: 'إعادة',
            color: const Color(0xFFEF4444), onTap: _reset, active: true),
      ],
    );
  }

  // ── Ambient selector ───────────────────────────────────────────────────────
  Widget _buildAmbientBar() {
    return ListenableBuilder(
      listenable: widget.ambientSvc,
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: glassDecoration(radius: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('صوت التركيز',
                      style: GoogleFonts.cairo(
                          color: Colors.white54, fontSize: 12)),
                  Row(
                    children: [
                      ...AmbientAudioService.ambientLabels.entries
                          .map((e) => _AmbientChip(
                                label:    e.value,
                                key_:     e.key,
                                isActive: widget.ambientSvc.activeKey == e.key &&
                                    widget.ambientSvc.isPlaying,
                                onTap: () async {
                                  if (widget.ambientSvc.activeKey == e.key &&
                                      widget.ambientSvc.isPlaying) {
                                    await widget.ambientSvc.pause();
                                  } else {
                                    await widget.ambientSvc.play(e.key);
                                  }
                                },
                              )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Task list ──────────────────────────────────────────────────────────────
  Widget _buildTaskList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: glassDecoration(radius: 24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskCtrl,
                        style: GoogleFonts.cairo(color: Colors.white),
                        onSubmitted: _addTask,
                        decoration: const InputDecoration(
                          labelText: 'أضف مهمة',
                          prefixIcon: Icon(Icons.task_alt_rounded,
                              color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedPressButton(
                      onTap: () => _addTask(_taskCtrl.text),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tasks.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 1),
                ...List.generate(
                  _tasks.length,
                  (i) => _TaskTile(
                    text: _tasks[i],
                    onDelete: () => _removeTask(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.sessionStore,
          builder: (_, __) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile & Gamification Header
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: glassDecoration(radius: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .2), shape: BoxShape.circle),
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.sessionStore.currentRank, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${widget.sessionStore.totalXp} XP', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.whatshot_rounded, color: widget.sessionStore.currentStreak > 0 ? Colors.deepOrangeAccent : Colors.white24, size: 28),
                          const SizedBox(width: 4),
                          Text('${widget.sessionStore.currentStreak}', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.architecture_rounded, color: Colors.white54, size: 22),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperPage()));
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Final Boss Exam Countdown
                CountdownWidget(examDate: DateTime(2026, 7, 1)),
                const SizedBox(height: 12),

                // Goal ring
                GoalVisualizer(
                  progress:       widget.sessionStore.todayProgress,
                  todayMinutes:   widget.sessionStore.todayMinutes,
                  goalMinutes:    widget.sessionStore.dailyGoalMinutes,
                  milestoneReached: widget.sessionStore.milestoneReached,
                ),
                const SizedBox(height: 12),
                const MotivationCard(),
                const SizedBox(height: 12),
                _buildTimerCard(),
                const SizedBox(height: 14),
                _buildControls(),
                const SizedBox(height: 12),
                _buildAmbientBar(),
                const SizedBox(height: 12),
                _buildTaskList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Neon Arc Painter ─────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final Color  primary;
  final Color  secondary;

  const _ArcPainter({
    required this.progress,
    required this.glowIntensity,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 10;
    const start = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start, 2 * math.pi, false,
      Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    if (progress <= 0) return;

    final shader = SweepGradient(
      startAngle: start,
      endAngle:   start + 2 * math.pi,
      colors:     [primary, secondary, primary],
      stops:      const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start, 2 * math.pi * progress, false,
      Paint()
        ..shader     = shader
        ..style      = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap  = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * glowIntensity),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}

// ── Control Button ─────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  final bool     active;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1.0 : 0.38,
      child: AnimatedPressButton(
        onTap: active ? onTap : null,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: color.withValues(alpha: .5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .28),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 5),
            Text(label,
                style:
                    GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Ambient Chip ───────────────────────────────────────────────────────────────
class _AmbientChip extends StatelessWidget {
  final String label;
  final String key_;
  final bool   isActive;
  final VoidCallback onTap;

  const _AmbientChip({
    required this.label,
    required this.key_,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedPressButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.secondary.withValues(alpha: .25) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cs.secondary : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isActive ? cs.secondary : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Task Tile ──────────────────────────────────────────────────────────────────
class _TaskTile extends StatefulWidget {
  final String text;
  final VoidCallback onDelete;
  const _TaskTile({required this.text, required this.onDelete});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _done = !_done);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _done ? const Color(0xFF10B981) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: _done ? const Color(0xFF10B981) : Colors.white38,
              width: 2,
            ),
          ),
          child: _done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        widget.text,
        style: GoogleFonts.cairo(
          color: _done ? Colors.white30 : Colors.white,
          decoration: _done ? TextDecoration.lineThrough : null,
          decorationColor: Colors.white30,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
        onPressed: widget.onDelete,
      ),
    );
  }
}
