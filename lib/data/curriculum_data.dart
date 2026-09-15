import '../models/grade_model.dart';
import 'curriculum_repository.dart';

/// واجهة البيانات المعتمدة لمناهج النحو العربي (Curriculum Data Facade).
/// تستخدم المستودع المركزي النمطي القابل للتوسع اللانهائي لدعم مئات الدروس والتمارين.
class CurriculumData {
  static List<GradeModel> getGrades() {
    return CurriculumRepository.instance.getAllGrades();
  }

  static GradeModel? getGrade(String id) {
    return CurriculumRepository.instance.getGradeById(id);
  }
}
