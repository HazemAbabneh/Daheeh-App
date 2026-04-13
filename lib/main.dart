import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/subject_model.dart';
import 'pages/home_page.dart';
import 'pages/subjects_page.dart';
import 'pages/settings_page.dart';
import 'services/ambient_audio_service.dart';
import 'services/notification_service.dart';
import 'services/session_store.dart';
import 'theme.dart';
import 'widgets/gyro_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-Edge
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    systemNavigationBarColor:          Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialise services
  await NotificationService().init();

  final prefs        = await SharedPreferences.getInstance();
  final subjectStore = SubjectStore();
  final sessionStore = SessionStore();
  final ambientSvc   = AmbientAudioService();

  await Future.wait([subjectStore.load(), sessionStore.load()]);

  runApp(MyApp(
    isDark:        prefs.getBool('isDark') ?? true,
    subjectStore:  subjectStore,
    sessionStore:  sessionStore,
    ambientSvc:    ambientSvc,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDark;
  final SubjectStore subjectStore;
  final SessionStore sessionStore;
  final AmbientAudioService ambientSvc;

  const MyApp({
    super.key,
    required this.isDark,
    required this.subjectStore,
    required this.sessionStore,
    required this.ambientSvc,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  void _toggleTheme() async {
    setState(() => _isDark = !_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title:                  'دحيح التوجيهي',
          debugShowCheckedModeBanner: false,
          theme: _isDark
              ? DahihTheme.fromDynamic(darkDynamic)
              : DahihTheme.light(),
          home: DahihShell(
            toggleTheme:  _toggleTheme,
            subjectStore: widget.subjectStore,
            sessionStore: widget.sessionStore,
            ambientSvc:   widget.ambientSvc,
          ),
        );
      },
    );
  }
}

// ── Main Shell ─────────────────────────────────────────────────────────────────
class DahihShell extends StatefulWidget {
  final VoidCallback toggleTheme;
  final SubjectStore subjectStore;
  final SessionStore sessionStore;
  final AmbientAudioService ambientSvc;

  const DahihShell({
    super.key,
    required this.toggleTheme,
    required this.subjectStore,
    required this.sessionStore,
    required this.ambientSvc,
  });

  @override
  State<DahihShell> createState() => _DahihShellState();
}

class _DahihShellState extends State<DahihShell> with AppLifecycleObserver {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const tabItems = [
      BottomNavigationBarItem(icon: Icon(Icons.timer_rounded),     label: 'الرئيسية'),
      BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded),  label: 'المواد'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_rounded),   label: 'الإعدادات'),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(),
      body: GyroBackground(
        accentColors: [cs.primary, cs.secondary],
        child: IndexedStack(
          index: _tab,
          children: [
            HomePage(
              toggleTheme:  widget.toggleTheme,
              sessionStore: widget.sessionStore,
              ambientSvc:   widget.ambientSvc,
            ),
            SubjectsPage(store: widget.subjectStore),
            SettingsPage(toggleTheme: widget.toggleTheme),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) {
              if (i == _tab) return;
              HapticFeedback.selectionClick();
              setState(() => _tab = i);
            },
            items: tabItems,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    const titles = ['دحيح التوجيهي', 'المواد الدراسية', 'الإعدادات'];
    return AppBar(
      title: Text(titles[_tab]),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6_rounded),
          onPressed: widget.toggleTheme,
        ),
      ],
    );
  }

  // Track app lifecycle for anti-distraction notifications
  @override
  void onInactive()  => NotificationService().showAntiDistractionAlert();
  @override
  void onResumed()   => NotificationService().cancelAll();
}

// ── App lifecycle mixin ────────────────────────────────────────────────────────
mixin AppLifecycleObserver<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      onInactive();
    } else if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }

  void onInactive() {}
  void onResumed()  {}

  // Required WidgetsBindingObserver stubs
  @override void didChangeMetrics() {}
  @override void didChangeTextScaleFactor() {}
  @override void didChangePlatformBrightness() {}
  @override void didChangeLocales(List<Locale>? ls) {}
  @override Future<bool> didPopRoute() async => false;
  @override Future<bool> didPushRoute(String r) async => false;
  @override Future<bool> didPushRouteInformation(RouteInformation r) async => false;
  @override void didChangeAccessibilityFeatures() {}
  @override void didHaveMemoryPressure() {}
  @override Future<AppExitResponse> didRequestAppExit() async => AppExitResponse.exit;
  @override void handleCancelBackGesture() {}
  @override void handleCommitBackGesture() {}
  @override bool handleStartBackGesture(PredictiveBackEvent e) => false;
  @override void handleUpdateBackGestureProgress(PredictiveBackEvent e) {}
  @override void didChangeViewFocus(ViewFocusEvent e) {}
}
