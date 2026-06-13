import 'package:flutter/material.dart';

enum FieldType { text, number, numberList, email, password, date, multiline }

class ResourceField {
  const ResourceField(
    this.key,
    this.labelKey, {
    this.type = FieldType.text,
    this.required = false,
  });

  final String key;
  final String labelKey;
  final FieldType type;
  final bool required;
}

class ResourceDefinition {
  const ResourceDefinition({
    required this.key,
    required this.titleKey,
    required this.endpoint,
    required this.icon,
    required this.fields,
    this.categoryKey = 'schoolRecords',
    this.subtitleKeys = const [],
    this.canWrite = true,
  });

  final String key;
  final String titleKey;
  final String endpoint;
  final IconData icon;
  final List<ResourceField> fields;
  final String categoryKey;
  final List<String> subtitleKeys;
  final bool canWrite;
}

const resourceDefinitions = <ResourceDefinition>[
  ResourceDefinition(
    key: 'students',
    titleKey: 'students',
    endpoint: '/students',
    icon: Icons.school_rounded,
    categoryKey: 'people',
    subtitleKeys: ['email', 'academic_year'],
    fields: [
      ResourceField('name', 'name', required: true),
      ResourceField('email', 'email', type: FieldType.email, required: true),
      ResourceField('password', 'password', type: FieldType.password),
      ResourceField('gender_id', 'gender'),
      ResourceField('nationalitie_id', 'nationality'),
      ResourceField('blood_id', 'bloodType'),
      ResourceField('Date_Birth', 'birthDate', type: FieldType.date),
      ResourceField('Grade_id', 'grade'),
      ResourceField('Classroom_id', 'classroom'),
      ResourceField('section_id', 'section'),
      ResourceField('parent_id', 'parent'),
      ResourceField('academic_year', 'academicYear'),
    ],
  ),
  ResourceDefinition(
    key: 'teachers',
    titleKey: 'teachers',
    endpoint: '/teachers',
    icon: Icons.badge_rounded,
    categoryKey: 'people',
    subtitleKeys: ['Email', 'Joining_Date'],
    fields: [
      ResourceField('Name', 'name', required: true),
      ResourceField('Email', 'email', type: FieldType.email, required: true),
      ResourceField('Password', 'password', type: FieldType.password),
      ResourceField('Specialization_id', 'specialization'),
      ResourceField('Gender_id', 'gender'),
      ResourceField('Joining_Date', 'joiningDate', type: FieldType.date),
      ResourceField('Address', 'address', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'parents',
    titleKey: 'parents',
    endpoint: '/parents',
    icon: Icons.family_restroom_rounded,
    categoryKey: 'people',
    subtitleKeys: ['email', 'Father_Phone'],
    fields: [
      ResourceField('Father_Name', 'fatherInfo', required: true),
      ResourceField('Father_National_ID', 'nationalId'),
      ResourceField('Father_Phone', 'phone'),
      ResourceField('Father_Job', 'job'),
      ResourceField('Mother_Name', 'motherInfo', required: true),
      ResourceField('Mother_National_ID', 'nationalId'),
      ResourceField('Mother_Phone', 'phone'),
      ResourceField('Mother_Job', 'job'),
      ResourceField('email', 'email', type: FieldType.email, required: true),
      ResourceField('password', 'password', type: FieldType.password),
      ResourceField(
        'password_confirmation',
        'password',
        type: FieldType.password,
      ),
    ],
  ),
  ResourceDefinition(
    key: 'grades',
    titleKey: 'grades',
    endpoint: '/grades',
    icon: Icons.layers_rounded,
    categoryKey: 'academics',
    fields: [
      ResourceField('Name', 'name', required: true),
      ResourceField('Notes', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'classrooms',
    titleKey: 'classrooms',
    endpoint: '/classrooms',
    icon: Icons.meeting_room_rounded,
    categoryKey: 'academics',
    fields: [
      ResourceField('Name_Class', 'name', required: true),
      ResourceField('Grade_id', 'grade'),
    ],
  ),
  ResourceDefinition(
    key: 'sections',
    titleKey: 'sections',
    endpoint: '/sections',
    icon: Icons.grid_view_rounded,
    categoryKey: 'academics',
    fields: [
      ResourceField('Name_Section', 'name', required: true),
      ResourceField('Grade_id', 'grade'),
      ResourceField('Class_id', 'classroom'),
    ],
  ),
  ResourceDefinition(
    key: 'subjects',
    titleKey: 'subjects',
    endpoint: '/subjects',
    icon: Icons.menu_book_rounded,
    categoryKey: 'academics',
    fields: [
      ResourceField('Name', 'name', required: true),
      ResourceField('Grade_id', 'grade'),
      ResourceField('Classroom_id', 'classroom'),
      ResourceField('teacher_id', 'teacher'),
    ],
  ),
  ResourceDefinition(
    key: 'fees',
    titleKey: 'fees',
    endpoint: '/fees',
    icon: Icons.payments_rounded,
    categoryKey: 'finance',
    fields: [
      ResourceField('title', 'name', required: true),
      ResourceField('amount', 'amount', type: FieldType.number, required: true),
      ResourceField('Grade_id', 'grade'),
      ResourceField('Classroom_id', 'classroom'),
      ResourceField('year', 'academicYear'),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'feeInvoices',
    titleKey: 'feeInvoices',
    endpoint: '/fees-invoices',
    icon: Icons.receipt_long_rounded,
    categoryKey: 'finance',
    fields: [
      ResourceField('student_id', 'students'),
      ResourceField('fee_id', 'fees'),
      ResourceField('amount', 'amount', type: FieldType.number),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'receipts',
    titleKey: 'receipts',
    endpoint: '/receipt-students',
    icon: Icons.request_quote_rounded,
    categoryKey: 'finance',
    fields: [
      ResourceField('student_id', 'students'),
      ResourceField('amount', 'amount', type: FieldType.number),
      ResourceField('date', 'date', type: FieldType.date),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'processingFees',
    titleKey: 'processingFees',
    endpoint: '/processing-fee',
    icon: Icons.price_change_rounded,
    categoryKey: 'finance',
    fields: [
      ResourceField('student_id', 'students'),
      ResourceField('amount', 'amount', type: FieldType.number),
      ResourceField('date', 'date', type: FieldType.date),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'payments',
    titleKey: 'payments',
    endpoint: '/payment-students',
    icon: Icons.account_balance_wallet_rounded,
    categoryKey: 'finance',
    fields: [
      ResourceField('student_id', 'students'),
      ResourceField('amount', 'amount', type: FieldType.number),
      ResourceField('date', 'date', type: FieldType.date),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'library',
    titleKey: 'library',
    endpoint: '/library',
    icon: Icons.local_library_rounded,
    categoryKey: 'learning',
    fields: [
      ResourceField('title', 'name', required: true),
      ResourceField('teacher_id', 'teacher'),
      ResourceField('Grade_id', 'grade'),
      ResourceField('Classroom_id', 'classroom'),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'onlineClasses',
    titleKey: 'onlineClasses',
    endpoint: '/online-classes',
    icon: Icons.video_camera_front_rounded,
    categoryKey: 'learning',
    fields: [
      ResourceField('grade_id', 'grade'),
      ResourceField('classroom_id', 'classroom'),
      ResourceField('section_id', 'section'),
      ResourceField('subject_id', 'subject'),
      ResourceField('teacher_id', 'teacher'),
      ResourceField('meeting_link', 'description'),
      ResourceField('date', 'date', type: FieldType.date),
    ],
  ),
  ResourceDefinition(
    key: 'quizzes',
    titleKey: 'quizzes',
    endpoint: '/quizzes',
    icon: Icons.quiz_rounded,
    categoryKey: 'exams',
    fields: [
      ResourceField('title', 'name', required: true),
      ResourceField('subject_id', 'subject'),
      ResourceField('teacher_id', 'teacher'),
      ResourceField('date', 'date', type: FieldType.date),
      ResourceField('description', 'description', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'questions',
    titleKey: 'questions',
    endpoint: '/questions',
    icon: Icons.help_center_rounded,
    categoryKey: 'exams',
    fields: [
      ResourceField('quiz_id', 'quizzes'),
      ResourceField(
        'question_text',
        'name',
        type: FieldType.multiline,
        required: true,
      ),
      ResourceField('correct_answer', 'description'),
      ResourceField('points', 'amount', type: FieldType.number),
    ],
  ),
  ResourceDefinition(
    key: 'graduated',
    titleKey: 'graduated',
    endpoint: '/graduated',
    icon: Icons.workspace_premium_rounded,
    categoryKey: 'studentsWorkflow',
    fields: [
      ResourceField(
        'student_ids',
        'studentIds',
        type: FieldType.numberList,
        required: true,
      ),
      ResourceField(
        'graduation_date',
        'graduationDate',
        type: FieldType.date,
        required: true,
      ),
      ResourceField('graduation_notes', 'notes', type: FieldType.multiline),
    ],
  ),
  ResourceDefinition(
    key: 'promotion',
    titleKey: 'promotion',
    endpoint: '/promotion',
    icon: Icons.trending_up_rounded,
    categoryKey: 'studentsWorkflow',
    fields: [
      ResourceField(
        'student_ids',
        'studentIds',
        type: FieldType.numberList,
        required: true,
      ),
      ResourceField('from_grade_id', 'fromGrade'),
      ResourceField('from_classroom_id', 'fromClassroom'),
      ResourceField('from_section_id', 'fromSection'),
      ResourceField('to_grade_id', 'toGrade', required: true),
      ResourceField('to_classroom_id', 'toClassroom', required: true),
      ResourceField('to_section_id', 'toSection', required: true),
      ResourceField(
        'promotion_date',
        'promotionDate',
        type: FieldType.date,
        required: true,
      ),
    ],
  ),
  ResourceDefinition(
    key: 'specializations',
    titleKey: 'specializations',
    endpoint: '/specializations',
    icon: Icons.psychology_rounded,
    categoryKey: 'lookups',
    canWrite: false,
    fields: [ResourceField('Name', 'name')],
  ),
  ResourceDefinition(
    key: 'genders',
    titleKey: 'genders',
    endpoint: '/genders',
    icon: Icons.wc_rounded,
    categoryKey: 'lookups',
    canWrite: false,
    fields: [ResourceField('Name', 'name')],
  ),
  ResourceDefinition(
    key: 'nationalities',
    titleKey: 'nationalities',
    endpoint: '/nationalities',
    icon: Icons.flag_rounded,
    categoryKey: 'lookups',
    canWrite: false,
    fields: [ResourceField('Name', 'name')],
  ),
  ResourceDefinition(
    key: 'bloodTypes',
    titleKey: 'bloodTypes',
    endpoint: '/blood-types',
    icon: Icons.bloodtype_rounded,
    categoryKey: 'lookups',
    canWrite: false,
    fields: [ResourceField('Name', 'name')],
  ),
  ResourceDefinition(
    key: 'settings',
    titleKey: 'settings',
    endpoint: '/settings',
    icon: Icons.settings_rounded,
    categoryKey: 'system',
    fields: [
      ResourceField('school_name', 'name'),
      ResourceField('phone', 'phone'),
      ResourceField('address', 'address', type: FieldType.multiline),
    ],
  ),
];

ResourceDefinition resourceByKey(String key) {
  return resourceDefinitions.firstWhere((resource) => resource.key == key);
}
