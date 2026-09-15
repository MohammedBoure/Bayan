import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

/// Manages pupil progress, completed lessons, evaluation scores, and app settings.
class ProgressService extends ChangeNotifier {
  static const String _keyCompletedLessons = 'completed_lessons';
  static const String _keyTotalStars = 'total_stars';
  static const String _keyTotalExercises = 'total_exercises';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyShowTashkeel = 'show_tashkeel';
  static const String _keyFontSizeScale = 'font_size_scale';

  SharedPreferences? _prefs;
  UserProgress _progress = UserProgress();

  bool _soundEnabled = true;
  bool _showTashkeel = true;
  double _fontSizeScale = 1.0;

  UserProgress get progress => _progress;
  bool get soundEnabled => _soundEnabled;
  bool get showTashkeel => _showTashkeel;
  double get fontSizeScale => _fontSizeScale;

  /// Initializes SharedPreferences and loads saved student progress.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadState();
    } catch (e) {
      debugPrint('ProgressService initialization fallback: $e');
    }
  }

  void _loadState() {
    if (_prefs == null) return;

    final completedList = _prefs!.getStringList(_keyCompletedLessons) ?? [];
    final Map<String, bool> completed = {for (var id in completedList) id: true};

    final totalStars = _prefs!.getInt(_keyTotalStars) ?? 0;
    final totalExercises = _prefs!.getInt(_keyTotalExercises) ?? 0;

    _soundEnabled = _prefs!.getBool(_keySoundEnabled) ?? true;
    _showTashkeel = _prefs!.getBool(_keyShowTashkeel) ?? true;
    _fontSizeScale = _prefs!.getDouble(_keyFontSizeScale) ?? 1.0;

    // Load lesson scores
    final Map<String, int> lessonScores = {};
    for (var key in _prefs!.getKeys()) {
      if (key.startsWith('score_lesson_')) {
        final lessonId = key.replaceFirst('score_lesson_', '');
        lessonScores[lessonId] = _prefs!.getInt(key) ?? 0;
      }
    }

    // Load grade scores
    final Map<String, int> gradeScores = {};
    for (var key in _prefs!.getKeys()) {
      if (key.startsWith('score_grade_')) {
        final gradeId = key.replaceFirst('score_grade_', '');
        gradeScores[gradeId] = _prefs!.getInt(key) ?? 0;
      }
    }

    _progress = UserProgress(
      completedLessons: completed,
      lessonScores: lessonScores,
      gradeScores: gradeScores,
      totalStars: totalStars,
      totalExercisesCompleted: totalExercises,
    );

    notifyListeners();
  }

  /// Marks a lesson as successfully completed and adds stars.
  Future<void> markLessonCompleted(String lessonId, {int starsEarned = 3}) async {
    final completed = Map<String, bool>.from(_progress.completedLessons);
    completed[lessonId] = true;

    final newStars = _progress.totalStars + starsEarned;
    final newExercises = _progress.totalExercisesCompleted + 1;

    _progress = _progress.copyWith(
      completedLessons: completed,
      totalStars: newStars,
      totalExercisesCompleted: newExercises,
    );

    if (_prefs != null) {
      await _prefs!.setStringList(_keyCompletedLessons, completed.keys.toList());
      await _prefs!.setInt(_keyTotalStars, newStars);
      await _prefs!.setInt(_keyTotalExercises, newExercises);
    }

    notifyListeners();
  }

  /// Saves the score from a comprehensive evaluation quiz.
  Future<void> saveGradeQuizScore(String gradeId, int score) async {
    final gradeScores = Map<String, int>.from(_progress.gradeScores);
    final previousBest = gradeScores[gradeId] ?? 0;
    if (score > previousBest) {
      gradeScores[gradeId] = score;
    }

    final newStars = _progress.totalStars + (score > 80 ? 3 : (score > 50 ? 2 : 1));

    _progress = _progress.copyWith(
      gradeScores: gradeScores,
      totalStars: newStars,
    );

    if (_prefs != null) {
      await _prefs!.setInt('score_grade_$gradeId', score);
      await _prefs!.setInt(_keyTotalStars, newStars);
    }

    notifyListeners();
  }

  /// Updates sound effects toggle.
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keySoundEnabled, value);
    }
    notifyListeners();
  }

  /// Updates tashkeel default visibility toggle.
  Future<void> setShowTashkeel(bool value) async {
    _showTashkeel = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keyShowTashkeel, value);
    }
    notifyListeners();
  }

  /// Updates font size scale.
  Future<void> setFontSizeScale(double scale) async {
    _fontSizeScale = scale;
    if (_prefs != null) {
      await _prefs!.setDouble(_keyFontSizeScale, scale);
    }
    notifyListeners();
  }

  /// Resets all student progress and statistics.
  Future<void> resetProgress() async {
    _progress = UserProgress();
    if (_prefs != null) {
      await _prefs!.remove(_keyCompletedLessons);
      await _prefs!.remove(_keyTotalStars);
      await _prefs!.remove(_keyTotalExercises);
      for (var key in _prefs!.getKeys().toList()) {
        if (key.startsWith('score_')) {
          await _prefs!.remove(key);
        }
      }
    }
    notifyListeners();
  }
}
