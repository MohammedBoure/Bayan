import '../models/activity_model.dart';
import '../models/grade_model.dart';
import '../models/lesson_model.dart';
import 'packs/grade3_curriculum_pack.dart';
import 'packs/grade4_curriculum_pack.dart';
import 'packs/grade5_curriculum_pack.dart';

/// المستودع المركزي للمناهج والدروس والتمارين (Curriculum Repository)
/// مصمم بطريقة نمطية وقابلة للتوسع اللانهائي، لاستقبال مئات الدروس والأنشطة الإضافية.
class CurriculumRepository {
  static final CurriculumRepository instance = CurriculumRepository._internal();
  CurriculumRepository._internal() {
    _loadDefaultPacks();
  }

  final Map<String, GradeModel> _grades = {};

  void _loadDefaultPacks() {
    registerGrade(Grade3CurriculumPack.buildGrade());
    registerGrade(Grade4CurriculumPack.buildGrade());
    registerGrade(Grade5CurriculumPack.buildGrade());
  }

  /// تسجيل سنة دراسية كاملة بحزمها ووحداتها
  void registerGrade(GradeModel grade) {
    _grades[grade.id] = grade;
  }

  /// استرجاع كافة السنوات الدراسية المسجلة
  List<GradeModel> getAllGrades() {
    return _grades.values.toList()..sort((a, b) => a.gradeNumber.compareTo(b.gradeNumber));
  }

  /// استرجac سنة دراسية محددة بمعرفها
  GradeModel? getGradeById(String gradeId) {
    return _grades[gradeId];
  }

  /// إضافة درس جديد ديناميكياً لأي سنة دراسية
  void addLessonToGrade(String gradeId, LessonModel lesson) {
    final grade = _grades[gradeId];
    if (grade != null) {
      final updatedLessons = List<LessonModel>.from(grade.lessons)..add(lesson);
      _grades[gradeId] = GradeModel(
        id: grade.id,
        gradeNumber: grade.gradeNumber,
        title: grade.title,
        subtitle: grade.subtitle,
        description: grade.description,
        imagePath: grade.imagePath,
        colorHex: grade.colorHex,
        units: grade.units,
        lessons: updatedLessons,
        comprehensiveQuiz: grade.comprehensiveQuiz,
      );
    }
  }

  /// إضافة نشاط أو تمرين جديد لأي درس
  void addActivityToLesson(String lessonId, ActivityModel activity) {
    for (final gradeEntry in _grades.entries) {
      final grade = gradeEntry.value;
      final lessonIndex = grade.lessons.indexWhere((l) => l.id == lessonId);
      if (lessonIndex != -1) {
        final lesson = grade.lessons[lessonIndex];
        final updatedActivities = List<ActivityModel>.from(lesson.activities)..add(activity);
        final updatedLesson = LessonModel(
          id: lesson.id,
          gradeId: lesson.gradeId,
          title: lesson.title,
          subtitle: lesson.subtitle,
          ruleSummary: lesson.ruleSummary,
          detailedExplanation: lesson.detailedExplanation,
          examples: lesson.examples,
          keyTakeaways: lesson.keyTakeaways,
          activities: updatedActivities,
          evaluationQuiz: lesson.evaluationQuiz,
          iconName: lesson.iconName,
        );
        final updatedLessons = List<LessonModel>.from(grade.lessons)..[lessonIndex] = updatedLesson;
        _grades[grade.id] = GradeModel(
          id: grade.id,
          gradeNumber: grade.gradeNumber,
          title: grade.title,
          subtitle: grade.subtitle,
          description: grade.description,
          imagePath: grade.imagePath,
          colorHex: grade.colorHex,
          units: grade.units,
          lessons: updatedLessons,
          comprehensiveQuiz: grade.comprehensiveQuiz,
        );
        break;
      }
    }
  }

  /// إجمالي عدد الدروس في البرنامج كاملاً
  int get totalLessonsCount => _grades.values.fold(0, (sum, g) => sum + g.totalLessonsCount);

  /// إجمالي عدد الأنشطة والتمارين في البرنامج كاملاً
  int get totalActivitiesCount => _grades.values.fold(0, (sum, g) => sum + g.totalActivitiesCount);
}
