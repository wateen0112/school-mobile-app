import '../models/app_models.dart';

class ModuleApiConfig {
  const ModuleApiConfig({
    required this.endpoint,
    this.createEndpoint,
    this.updateEndpoint,
    this.deleteEndpoint,
    this.createMethod = 'post',
    this.idField = 'id',
    this.fieldMap = const {},
    this.defaultPayload = const {},
    this.listQuery = const {},
  });

  final String endpoint;
  final String? createEndpoint;
  final String? updateEndpoint;
  final String? deleteEndpoint;
  final String createMethod;
  final String idField;
  final Map<String, String> fieldMap;
  final Map<String, dynamic> defaultPayload;
  final Map<String, dynamic> listQuery;
}

const _defaults = <String, dynamic>{
  'Name_ar': 'اسم تجريبي',
  'Name_en': 'Sample name',
  'Name': 'اسم تجريبي',
  'Name_Section_Ar': 'القسم أ',
  'Name_Section_En': 'Section A',
  'Grade_id': 1,
  'Class_id': 1,
  'Classroom_id': 1,
  'section_id': 1,
  'teacher_id': 1,
  'student_id': 1,
  'parent_id': 1,
  'gender_id': 1,
  'nationalitie_id': 1,
  'blood_id': 1,
  'Specialization_id': 1,
  'Gender_id': 1,
  'academic_year': '2025',
  'academic_year_new': '2026',
  'Date_Birth': '2015-01-01',
  'Joining_Date': '2025-01-01',
  'Password': 'password123',
  'password': 'password123',
  'Address': 'School address',
  'Email': 'sample@example.com',
  'email': 'sample@example.com',
  'description': 'Created from mobile app',
  'Debit': 100,
  'amount': 100,
  'title_ar': 'رسوم تجريبية',
  'title_en': 'Sample fee',
  'year': '2025',
  'Fee_type': 1,
  'fee_id': 1,
  'subject_id': 1,
  'quizze_id': 1,
  'title': 'Sample title',
  'answers': 'A,B,C,D',
  'right_answer': 'A',
  'score': 1,
};

final moduleApiConfigs = <String, ModuleApiConfig>{
  'genders': ModuleApiConfig(endpoint: '/genders'),
  'nationalities': ModuleApiConfig(endpoint: '/nationalities'),
  'blood-types': ModuleApiConfig(endpoint: '/blood-types'),
  'specializations': ModuleApiConfig(endpoint: '/specializations'),
  'grades': ModuleApiConfig(
    endpoint: '/Grades',
    fieldMap: {'name': 'Name_en', 'notes': 'Notes'},
    defaultPayload: {'Name': 'مرحلة تجريبية', 'Name_en': 'Sample grade'},
  ),
  'classrooms': ModuleApiConfig(
    endpoint: '/Classrooms',
    fieldMap: {'name': 'Name', 'grade': 'Grade_id'},
    defaultPayload: {
      'List_Classes': [
        {
          'Name': 'صف تجريبي',
          'Name_class_en': 'Sample classroom',
          'Grade_id': 1,
        },
      ],
    },
  ),
  'sections': ModuleApiConfig(
    endpoint: '/Sections',
    fieldMap: {
      'name': 'Name_Section_En',
      'grade': 'Grade_id',
      'classroom': 'Class_id',
      'teachers': 'teacher_id',
    },
    defaultPayload: {
      'Name_Section_Ar': 'القسم أ',
      'Name_Section_En': 'Section A',
      'Grade_id': 1,
      'Class_id': 1,
      'teacher_id': [1],
    },
  ),
  'students': ModuleApiConfig(
    endpoint: '/Students',
    fieldMap: {
      'name': 'name_en',
      'email': 'email',
      'password': 'password',
      'birthDate': 'Date_Birth',
      'gender': 'gender_id',
      'nationality': 'nationalitie_id',
      'bloodType': 'blood_id',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'section': 'section_id',
      'parent': 'parent_id',
      'academicYear': 'academic_year',
    },
    defaultPayload: {'name_ar': 'طالب تجريبي', 'academic_year': '2025'},
  ),
  'teachers': ModuleApiConfig(
    endpoint: '/Teachers',
    fieldMap: {
      'name': 'Name_en',
      'email': 'Email',
      'password': 'Password',
      'specialization': 'Specialization_id',
      'gender': 'Gender_id',
      'joiningDate': 'Joining_Date',
      'address': 'Address',
    },
    defaultPayload: {
      'Name_ar': 'معلم تجريبي',
      'Joining_Date': '2025-01-01',
      'Address': 'School address',
    },
  ),
  'parents': ModuleApiConfig(
    endpoint: '/parents',
    fieldMap: {
      'fatherName': 'Father_Name',
      'fatherNationalId': 'Father_National_ID',
      'email': 'email',
      'password': 'password',
    },
  ),
  'fees': ModuleApiConfig(
    endpoint: '/Fees',
    fieldMap: {
      'title': 'title_en',
      'amount': 'amount',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'status': 'Fee_type',
    },
    defaultPayload: _defaults,
  ),
  'invoices': ModuleApiConfig(
    endpoint: '/Fees_Invoices',
    fieldMap: {'student': 'student_id', 'fee': 'fee_id', 'amount': 'amount'},
    defaultPayload: {
      'Grade_id': 1,
      'Classroom_id': 1,
      'List_Fees': [
        {
          'student_id': 1,
          'fee_id': 1,
          'amount': 100,
          'description': 'Mobile invoice',
        },
      ],
    },
  ),
  'receipts': ModuleApiConfig(
    endpoint: '/receipt_students',
    fieldMap: {
      'student': 'student_id',
      'amount': 'Debit',
      'notes': 'description',
    },
    defaultPayload: {
      'student_id': 1,
      'Debit': 100,
      'description': 'Mobile receipt',
    },
  ),
  'payments': ModuleApiConfig(
    endpoint: '/Payment_students',
    fieldMap: {'student': 'student_id', 'amount': 'Debit'},
    defaultPayload: {
      'student_id': 1,
      'Debit': 100,
      'description': 'Mobile payment',
    },
  ),
  'attendance': ModuleApiConfig(
    endpoint: '/Attendance',
    defaultPayload: {
      'grade_id': 1,
      'classroom_id': 1,
      'section_id': 1,
      'attendences': {'1': 'presence'},
    },
  ),
  'subjects': ModuleApiConfig(
    endpoint: '/subjects',
    fieldMap: {
      'name': 'Name_en',
      'grade': 'Grade_id',
      'classroom': 'Class_id',
      'teacher': 'teacher_id',
    },
    defaultPayload: {
      'Name_ar': 'مادة تجريبية',
      'Name_en': 'Sample Subject',
      ..._defaults,
    },
  ),
  'quizzes': ModuleApiConfig(
    endpoint: '/Quizzes',
    fieldMap: {
      'title': 'Name_en',
      'subject': 'subject_id',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'section': 'section_id',
      'teacher': 'teacher_id',
      'timeLimit': 'description',
    },
    defaultPayload: {
      'Name_ar': 'اختبار تجريبي',
      'Name_en': 'Sample Quiz',
      ..._defaults,
    },
  ),
  'questions': ModuleApiConfig(
    endpoint: '/questions',
    fieldMap: {
      'question': 'title',
      'quiz': 'quizze_id',
      'options': 'answers',
      'correct': 'right_answer',
      'score': 'score',
    },
    defaultPayload: _defaults,
  ),
  'library': ModuleApiConfig(
    endpoint: '/library',
    fieldMap: {
      'title': 'title',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'section': 'section_id',
      'teacher': 'teacher_id',
    },
    defaultPayload: _defaults,
  ),
  'online-classes': ModuleApiConfig(
    endpoint: '/online_classes',
    fieldMap: {
      'title': 'topic',
      'meetingUrl': 'join_url',
      'time': 'start_at',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'section': 'section_id',
      'subject': 'subject_id',
      'teacher': 'teacher_id',
    },
    defaultPayload: _defaults,
  ),
  'promotions': ModuleApiConfig(
    endpoint: '/promotion',
    fieldMap: {
      'fromGrade': 'Grade_id',
      'fromClassroom': 'Classroom_id',
      'fromSection': 'section_id',
      'academicYear': 'academic_year',
      'toGrade': 'Grade_id_new',
      'toClassroom': 'Classroom_id_new',
      'toSection': 'section_id_new',
      'academicYearNew': 'academic_year_new',
    },
    defaultPayload: {
      'Grade_id': 1,
      'Classroom_id': 1,
      'section_id': 1,
      'academic_year': '2024-2025',
      'Grade_id_new': 1,
      'Classroom_id_new': 1,
      'section_id_new': 1,
      'academic_year_new': '2025-2026',
    },
  ),
  'graduated': ModuleApiConfig(
    endpoint: '/Graduated',
    fieldMap: {
      'students': 'student_id',
      'grade': 'Grade_id',
      'classroom': 'Classroom_id',
      'section': 'section_id',
    },
    defaultPayload: {'Grade_id': 1, 'Classroom_id': 1, 'section_id': 1},
  ),
  'settings': ModuleApiConfig(endpoint: '/settings'),
  'teacher-sections': ModuleApiConfig(endpoint: '/Sections'),
  'teacher-students': ModuleApiConfig(endpoint: '/Students'),
  'teacher-attendance': ModuleApiConfig(endpoint: '/Attendance'),
  'teacher-quizzes': ModuleApiConfig(endpoint: '/Quizzes'),
  'teacher-questions': ModuleApiConfig(endpoint: '/questions'),
  'teacher-online': ModuleApiConfig(endpoint: '/online_classes'),
  'teacher-profile': ModuleApiConfig(endpoint: '/Teachers'),
  'student-exams': ModuleApiConfig(endpoint: '/Quizzes'),
  'student-profile': ModuleApiConfig(endpoint: '/Students'),
  'parent-children': ModuleApiConfig(endpoint: '/Students'),
  'parent-attendance': ModuleApiConfig(endpoint: '/Attendance'),
  'parent-finance': ModuleApiConfig(endpoint: '/Fees'),
  'parent-profile': ModuleApiConfig(endpoint: '/parents'),
};

ModuleApiConfig? apiConfigFor(ModuleSpec module) =>
    moduleApiConfigs[module.key];

ModuleApiConfig? apiConfigForKey(String key) => moduleApiConfigs[key];
