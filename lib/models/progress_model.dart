/// Tracks pupil progress, scores, stars, and completion state across lessons and grades.
class UserProgress {
  final Map<String, bool> completedLessons;
  final Map<String, int> lessonScores;
  final Map<String, int> gradeScores; // High score per grade quiz
  final int totalStars;
  final int totalExercisesCompleted;

  UserProgress({
    Map<String, bool>? completedLessons,
    Map<String, int>? lessonScores,
    Map<String, int>? gradeScores,
    this.totalStars = 0,
    this.totalExercisesCompleted = 0,
  })  : completedLessons = completedLessons ?? {},
        lessonScores = lessonScores ?? {},
        gradeScores = gradeScores ?? {};

  bool isLessonCompleted(String lessonId) => completedLessons[lessonId] ?? false;

  int getLessonScore(String lessonId) => lessonScores[lessonId] ?? 0;

  int getGradeScore(String gradeId) => gradeScores[gradeId] ?? 0;

  UserProgress copyWith({
    Map<String, bool>? completedLessons,
    Map<String, int>? lessonScores,
    Map<String, int>? gradeScores,
    int? totalStars,
    int? totalExercisesCompleted,
  }) {
    return UserProgress(
      completedLessons: completedLessons ?? Map.from(this.completedLessons),
      lessonScores: lessonScores ?? Map.from(this.lessonScores),
      gradeScores: gradeScores ?? Map.from(this.gradeScores),
      totalStars: totalStars ?? this.totalStars,
      totalExercisesCompleted: totalExercisesCompleted ?? this.totalExercisesCompleted,
    );
  }
}
