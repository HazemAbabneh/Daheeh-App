import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<Color> subjectColors = [
  Color(0xFF7C3AED), Color(0xFF22D3EE), Color(0xFF10B981), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFFF472B6), Color(0xFF84CC16),
];

class Unit {
  final String id;
  String title;
  bool isStudied;
  bool isReviewed;
  bool isSolved;
  DateTime? nextReviewDate;

  Unit({
    required this.id,
    required this.title,
    this.isStudied = false,
    this.isReviewed = false,
    this.isSolved = false,
    this.nextReviewDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isStudied': isStudied,
    'isReviewed': isReviewed,
    'isSolved': isSolved,
    'nextReviewDate': nextReviewDate?.toIso8601String(),
  };

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
    id: j['id'] as String,
    title: j['title'] as String,
    isStudied: j['isStudied'] as bool? ?? false,
    isReviewed: j['isReviewed'] as bool? ?? false,
    isSolved: j['isSolved'] as bool? ?? false,
    nextReviewDate: j['nextReviewDate'] != null ? DateTime.parse(j['nextReviewDate']) : null,
  );
}

class Subject {
  final String id;
  String name;
  String category;
  bool isArchived;
  List<Unit> units;
  final int colorIndex;

  Subject({
    required this.id,
    required this.name,
    this.category = 'عام',
    this.isArchived = false,
    List<Unit>? units,
    required this.colorIndex,
  }) : units = units ?? [];

  Color get color => subjectColors[colorIndex % subjectColors.length];

  double get progress {
    if (units.isEmpty) return 0.0;
    int total = units.length * 3;
    int done = units.fold(0, (sum, u) => sum + (u.isStudied ? 1 : 0) + (u.isReviewed ? 1 : 0) + (u.isSolved ? 1 : 0));
    return done / total;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'isArchived': isArchived,
    'units': units.map((u) => u.toJson()).toList(),
    'colorIndex': colorIndex,
  };

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String? ?? 'عام',
    isArchived: j['isArchived'] as bool? ?? false,
    units: (j['units'] as List?)?.map((u) => Unit.fromJson(u)).toList() ?? [],
    colorIndex: j['colorIndex'] as int,
  );
}

class SubjectStore extends ChangeNotifier {
  static const _key = 'dahih_subjects_v2';

  final List<Subject> _subjects = [];

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Subject> get activeSubjects => _subjects.where((s) => !s.isArchived).toList();
  List<Subject> get archivedSubjects => _subjects.where((s) => s.isArchived).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // try v2 key first, then fallback to v1 for migration
    final raw = prefs.getString(_key) ?? prefs.getString('dahih_subjects');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _subjects
        ..clear()
        ..addAll(list.map((e) => Subject.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    }
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_subjects.map((s) => s.toJson()).toList()));
  }

  Future<void> add(String name, String category) async {
    _subjects.add(Subject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      colorIndex: _subjects.length,
    ));
    notifyListeners();
    await persist();
  }

  Future<void> remove(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
    await persist();
  }

  // Direct unit mutations for UI ease
  Future<void> addUnit(String subjectId, String title) async {
    final s = _subjects.firstWhere((s) => s.id == subjectId);
    s.units.add(Unit(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title));
    notifyListeners();
    await persist();
  }

  Future<void> toggleArchive(String subjectId) async {
    final s = _subjects.firstWhere((s) => s.id == subjectId);
    s.isArchived = !s.isArchived;
    notifyListeners();
    await persist();
  }
}
