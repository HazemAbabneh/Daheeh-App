import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = "دحيح التوجيهي";
  static const Color primaryColor = Color(0xFF0A73FF);
  static const Color accentColor = Color(0xFFFFC107);

  static const int pomodoroMinutes = 25;

  // App icon (used by flutter_launcher_icons + any in-app display)
  static const String appIcon = "assets/icons/app_icon.png";

  // Sound assets — filenames match assets/sounds/ on disk
  static const String soundPomodoroEnd = "sounds/pomodoro_end.wav";
  static const String soundTaskAdded   = "sounds/task_added.wav";
  static const String soundTaskRemoved = "sounds/task_removed.wav";
}

