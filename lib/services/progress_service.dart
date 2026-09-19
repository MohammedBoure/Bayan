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
  static const String _keyTeacherModeEnabled = 'teacher_mode_enabled';
  static const String _keyRevealAnswersDirectly = 'reveal_answers_directly';
  static const String _keyTimerDuration = 'timer_duration';
  static const String _keySpotlightReading = 'spotlight_reading';
  static const String _keyNlpAutoAnalysis = 'nlp_auto_analysis';
  static const String _keySelectedFontFamily = 'selected_font_family';

  static const String defaultFontFamily = 'NotoNaskhArabic';

  SharedPreferences? _prefs;
  UserProgress _progress = UserProgress();

  bool _soundEnabled = true;
  bool _showTashkeel = true;
  double _fontSizeScale = 1.0;
  String _selectedFontFamily = defaultFontFamily;
  bool _teacherModeEnabled = true;
  bool _revealAnswersDirectly = false;
  int _timerDuration = 45; // 0 = no timer, 30, 45, 60, 90 seconds
  bool _spotlightReading = true;
  bool _nlpAutoAnalysis = true;

  UserProgress get progress => _progress;
  bool get soundEnabled => _soundEnabled;
  bool get showTashkeel => _showTashkeel;
  double get fontSizeScale => _fontSizeScale;
  String get selectedFontFamily => _selectedFontFamily;
  bool get teacherModeEnabled => _teacherModeEnabled;
  bool get revealAnswersDirectly => _revealAnswersDirectly;
  int get timerDuration => _timerDuration;
  bool get spotlightReading => _spotlightReading;
  bool get nlpAutoAnalysis => _nlpAutoAnalysis;

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
    _selectedFontFamily = _prefs!.getString(_keySelectedFontFamily) ?? defaultFontFamily;
    _teacherModeEnabled = _prefs!.getBool(_keyTeacherModeEnabled) ?? true;
    _revealAnswersDirectly = _prefs!.getBool(_keyRevealAnswersDirectly) ?? false;
    _timerDuration = _prefs!.getInt(_keyTimerDuration) ?? 45;
    _spotlightReading = _prefs!.getBool(_keySpotlightReading) ?? true;
    _nlpAutoAnalysis = _prefs!.getBool(_keyNlpAutoAnalysis) ?? true;

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

  /// Updates selected Arabic font family.
  Future<void> setSelectedFontFamily(String family) async {
    _selectedFontFamily = family;
    if (_prefs != null) {
      await _prefs!.setString(_keySelectedFontFamily, family);
    }
    notifyListeners();
  }

  /// Updates teacher presentation mode toggle.
  Future<void> setTeacherModeEnabled(bool value) async {
    _teacherModeEnabled = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keyTeacherModeEnabled, value);
    }
    notifyListeners();
  }

  /// Updates whether model answers are revealed directly to teacher.
  Future<void> setRevealAnswersDirectly(bool value) async {
    _revealAnswersDirectly = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keyRevealAnswersDirectly, value);
    }
    notifyListeners();
  }

  /// Updates classroom activity challenge timer duration (in seconds, 0 = disabled).
  Future<void> setTimerDuration(int seconds) async {
    _timerDuration = seconds;
    if (_prefs != null) {
      await _prefs!.setInt(_keyTimerDuration, seconds);
    }
    notifyListeners();
  }

  /// Updates spotlight reading focus toggle.
  Future<void> setSpotlightReading(bool value) async {
    _spotlightReading = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keySpotlightReading, value);
    }
    notifyListeners();
  }

  /// Updates live NLP linguistic analysis toggle.
  Future<void> setNlpAutoAnalysis(bool value) async {
    _nlpAutoAnalysis = value;
    if (_prefs != null) {
      await _prefs!.setBool(_keyNlpAutoAnalysis, value);
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
