import 'package:flutter/material.dart';

import '../models/app_models.dart';

const roleLabels = {
  UserRole.admin: 'Admin',
  UserRole.teacher: 'Teacher',
  UserRole.student: 'Student',
  UserRole.parent: 'Parent',
};

const adminModules = <ModuleSpec>[
  ModuleSpec(
    key: 'admin-dashboard',
    title: 'Dashboard',
    route: '/admin/dashboard',
    icon: Icons.dashboard_rounded,
    goal:
        'Administrative overview with stats, charts, recent activity, and quick actions.',
    group: 'Overview',
    columns: ['Metric', 'Value', 'Trend'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'dashboard',
  ),
  ModuleSpec(
    key: 'grades',
    title: 'Grades',
    route: '/admin/grades',
    icon: Icons.layers_rounded,
    goal: 'Manage school grade/stage records.',
    group: 'Grades',
    columns: ['Grade name', 'Notes', 'Actions'],
    fields: [FormFieldSpec(name: 'name', label: 'Grade name', required: true)],
  ),
  ModuleSpec(
    key: 'classrooms',
    title: 'Classrooms',
    route: '/admin/classrooms',
    icon: Icons.meeting_room_rounded,
    goal: 'Create and organize classrooms by grade.',
    group: 'Classrooms',
    columns: ['Classroom', 'Grade', 'Students', 'Actions'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Classroom name', required: true),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
    ],
  ),
  ModuleSpec(
    key: 'sections',
    title: 'Sections',
    route: '/admin/sections',
    icon: Icons.grid_view_rounded,
    goal: 'Manage sections and assign teachers.',
    group: 'Sections',
    columns: ['Section', 'Classroom', 'Teacher', 'Status'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Section name', required: true),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'teachers',
        label: 'Teachers',
        kind: FieldKind.multiSelect,
        dynamicOptionsKey: 'teachers',
      ),
    ],
  ),
  ModuleSpec(
    key: 'students',
    title: 'Students',
    route: '/admin/students',
    icon: Icons.school_rounded,
    goal: 'Search, filter, create, edit, and manage student records.',
    group: 'Students',
    columns: ['Name', 'Grade', 'Section', 'Email'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Student name', required: true),
      FormFieldSpec(
        name: 'email',
        label: 'Email',
        kind: FieldKind.email,
        required: true,
      ),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
        required: true,
      ),
      FormFieldSpec(
        name: 'birthDate',
        label: 'Birth date',
        kind: FieldKind.date,
        required: true,
      ),
      FormFieldSpec(
        name: 'gender',
        label: 'Gender',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'genders',
      ),
      FormFieldSpec(
        name: 'nationality',
        label: 'Nationality',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'nationalities',
      ),
      FormFieldSpec(
        name: 'bloodType',
        label: 'Blood type',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'blood-types',
      ),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'parent',
        label: 'Linked parent',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'parents',
      ),
      FormFieldSpec(
        name: 'academicYear',
        label: 'Academic year',
        required: true,
      ),
    ],
  ),
  ModuleSpec(
    key: 'promotions',
    title: 'Promotions',
    route: '/admin/students/promotions',
    icon: Icons.trending_up_rounded,
    goal:
        'Bulk promote students to a new grade, classroom, section, and academic year.',
    group: 'Students',
    columns: ['Student', 'From', 'To', 'Year'],
    fields: [
      FormFieldSpec(
        name: 'students',
        label: 'Students',
        kind: FieldKind.multiSelect,
        required: true,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(
        name: 'fromGrade',
        label: 'From grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'fromClassroom',
        label: 'From classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'fromSection',
        label: 'From section',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'academicYear',
        label: 'Current academic year',
        required: true,
      ),
      FormFieldSpec(
        name: 'toGrade',
        label: 'To grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'toClassroom',
        label: 'To classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'toSection',
        label: 'To section',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'academicYearNew',
        label: 'New academic year',
        required: true,
      ),
    ],
    hasDelete: false,
    specialView: 'bulkAction',
  ),
  ModuleSpec(
    key: 'graduated',
    title: 'Graduated Students',
    route: '/admin/students/graduated',
    icon: Icons.workspace_premium_rounded,
    goal: 'Archive graduated students and filter them by graduation year.',
    group: 'Students',
    columns: ['Student', 'Grade', 'Graduation year', 'Status'],
    fields: [
      FormFieldSpec(
        name: 'students',
        label: 'Students',
        kind: FieldKind.multiSelect,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'year',
        label: 'Graduation year',
        kind: FieldKind.number,
      ),
      FormFieldSpec(name: 'notes', label: 'Notes', kind: FieldKind.multiline),
    ],
    specialView: 'archive',
  ),
  ModuleSpec(
    key: 'teachers',
    title: 'Teachers',
    route: '/admin/teachers',
    icon: Icons.badge_rounded,
    goal: 'Manage teacher profiles, credentials, and assigned subjects.',
    group: 'Teachers',
    columns: ['Name', 'Subject', 'Joining date', 'Actions'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Teacher name', required: true),
      FormFieldSpec(
        name: 'email',
        label: 'Email',
        kind: FieldKind.email,
        required: true,
      ),
      FormFieldSpec(
        name: 'subjects',
        label: 'Assigned subjects',
        kind: FieldKind.multiSelect,
        dynamicOptionsKey: 'subjects',
      ),
      FormFieldSpec(
        name: 'specialization',
        label: 'Specialization',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'specializations',
      ),
      FormFieldSpec(
        name: 'gender',
        label: 'Gender',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'genders',
      ),
      FormFieldSpec(
        name: 'joiningDate',
        label: 'Joining date',
        kind: FieldKind.date,
        required: true,
      ),
      FormFieldSpec(name: 'address', label: 'Address', required: true),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
        required: true,
      ),
    ],
  ),
  ModuleSpec(
    key: 'parents',
    title: 'Parents',
    route: '/admin/parents',
    icon: Icons.family_restroom_rounded,
    goal:
        'Manage parent accounts and linked children through a father/mother/children wizard.',
    group: 'Parents',
    columns: ['Parent', 'Phone', 'Children', 'Email'],
    fields: [
      FormFieldSpec(name: 'fatherName', label: 'Father name', required: true),
      FormFieldSpec(
        name: 'fatherNationalId',
        label: 'Father national ID',
        required: true,
      ),
      FormFieldSpec(
        name: 'email',
        label: 'Email',
        kind: FieldKind.email,
        required: true,
      ),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
        required: true,
      ),
    ],
  ),
  ModuleSpec(
    key: 'fees',
    title: 'Fees',
    route: '/admin/accounts/fees',
    icon: Icons.payments_rounded,
    goal: 'Track fee amounts, due dates, and paid/unpaid status.',
    group: 'Accounts',
    columns: ['Student', 'Amount', 'Due date', 'Status'],
    fields: [
      FormFieldSpec(
        name: 'student',
        label: 'Student',
        kind: FieldKind.select,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(name: 'amount', label: 'Amount', kind: FieldKind.number),
      FormFieldSpec(name: 'dueDate', label: 'Due date', kind: FieldKind.date),
      FormFieldSpec(
        name: 'status',
        label: 'Status',
        kind: FieldKind.select,
        options: ['Paid', 'Unpaid'],
      ),
    ],
  ),
  ModuleSpec(
    key: 'invoices',
    title: 'Invoices',
    route: '/admin/accounts/invoices',
    icon: Icons.receipt_long_rounded,
    goal: 'Filter and manage invoices by date and status.',
    group: 'Accounts',
    columns: ['Invoice', 'Student', 'Date', 'Status'],
    fields: [
      FormFieldSpec(
        name: 'student',
        label: 'Student',
        kind: FieldKind.select,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(
        name: 'fee',
        label: 'Fee',
        kind: FieldKind.select,
        dynamicOptionsKey: 'fees',
      ),
      FormFieldSpec(name: 'amount', label: 'Amount', kind: FieldKind.number),
      FormFieldSpec(name: 'date', label: 'Invoice date', kind: FieldKind.date),
      FormFieldSpec(name: 'status', label: 'Status'),
    ],
  ),
  ModuleSpec(
    key: 'receipts',
    title: 'Receipts',
    route: '/admin/accounts/receipts',
    icon: Icons.request_quote_rounded,
    goal: 'View receipt history and provide download/print actions.',
    group: 'Accounts',
    columns: ['Receipt', 'Student', 'Amount', 'Download'],
    fields: [
      FormFieldSpec(
        name: 'student',
        label: 'Student',
        kind: FieldKind.select,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(name: 'amount', label: 'Amount', kind: FieldKind.number),
      FormFieldSpec(name: 'notes', label: 'Notes'),
    ],
  ),
  ModuleSpec(
    key: 'payments',
    title: 'Payments',
    route: '/admin/accounts/payments',
    icon: Icons.account_balance_wallet_rounded,
    goal: 'Maintain transaction log for outgoing or student-related payments.',
    group: 'Accounts',
    columns: ['Transaction', 'Student', 'Amount', 'Date'],
    fields: [
      FormFieldSpec(
        name: 'student',
        label: 'Student',
        kind: FieldKind.select,
        dynamicOptionsKey: 'students',
      ),
      FormFieldSpec(name: 'amount', label: 'Amount', kind: FieldKind.number),
      FormFieldSpec(name: 'date', label: 'Date', kind: FieldKind.date),
    ],
  ),
  ModuleSpec(
    key: 'attendance',
    title: 'Attendance',
    route: '/admin/attendance',
    icon: Icons.fact_check_rounded,
    goal: 'Calendar/grid overview and present/absent/late marking per student.',
    group: 'Attendance',
    columns: ['Student', 'Present', 'Absent', 'Late'],
    fields: [],
    specialView: 'attendance',
  ),
  ModuleSpec(
    key: 'attendance-history',
    title: 'Attendance History',
    route: '/admin/attendance/history',
    icon: Icons.history_rounded,
    goal:
        'Read-only attendance history filtered by grade, classroom, section, and date.',
    group: 'Attendance',
    columns: ['Student', 'Status', 'Date', 'Section'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'attendanceHistory',
  ),
  ModuleSpec(
    key: 'subjects',
    title: 'Subjects',
    route: '/admin/subjects',
    icon: Icons.menu_book_rounded,
    goal: 'Manage subject catalog and teacher/class relationships.',
    group: 'Subjects',
    columns: ['Subject', 'Grade', 'Teacher', 'Actions'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Subject name', required: true),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'teachers',
      ),
    ],
  ),
  ModuleSpec(
    key: 'quizzes',
    title: 'Quizzes',
    route: '/admin/exams/quizzes',
    icon: Icons.quiz_rounded,
    goal: 'Manage quizzes by title, subject, section, and date.',
    group: 'Exams',
    columns: ['Title', 'Subject', 'Section', 'Date'],
    fields: [
      FormFieldSpec(name: 'title', label: 'Quiz title', required: true),
      FormFieldSpec(
        name: 'subject',
        label: 'Subject',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'subjects',
      ),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        required: true,
        dynamicOptionsKey: 'teachers',
      ),
      FormFieldSpec(
        name: 'timeLimit',
        label: 'Time limit',
        kind: FieldKind.number,
      ),
    ],
    specialView: 'quiz',
  ),
  ModuleSpec(
    key: 'questions',
    title: 'Questions',
    route: '/admin/exams/questions',
    icon: Icons.help_center_rounded,
    goal: 'Create MCQ/true-false questions with options and correct answers.',
    group: 'Exams',
    columns: ['Question', 'Type', 'Quiz', 'Answer'],
    fields: [
      FormFieldSpec(
        name: 'question',
        label: 'Question text',
        kind: FieldKind.multiline,
        required: true,
      ),
      FormFieldSpec(
        name: 'type',
        label: 'Type',
        kind: FieldKind.select,
        options: ['MCQ', 'True/False'],
      ),
      FormFieldSpec(
        name: 'quiz',
        label: 'Quiz',
        kind: FieldKind.select,
        dynamicOptionsKey: 'quizzes',
      ),
      FormFieldSpec(
        name: 'options',
        label: 'Answer options',
        kind: FieldKind.multiline,
      ),
      FormFieldSpec(name: 'correct', label: 'Correct answer'),
    ],
  ),
  ModuleSpec(
    key: 'library',
    title: 'Library',
    route: '/admin/library',
    icon: Icons.local_library_rounded,
    goal: 'Manage books, categories, and availability status.',
    group: 'Library',
    columns: ['Title', 'Author', 'Category', 'Status'],
    fields: [
      FormFieldSpec(name: 'title', label: 'Book title'),
      FormFieldSpec(name: 'author', label: 'Author'),
      FormFieldSpec(name: 'category', label: 'Category'),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        dynamicOptionsKey: 'teachers',
      ),
    ],
  ),
  ModuleSpec(
    key: 'online-classes',
    title: 'Online Classes',
    route: '/admin/online-classes',
    icon: Icons.video_camera_front_rounded,
    goal: 'Schedule classes with meeting URLs and teacher assignment.',
    group: 'Online Classes',
    columns: ['Title', 'Teacher', 'Scheduled time', 'Link'],
    fields: [
      FormFieldSpec(name: 'title', label: 'Class title'),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'subject',
        label: 'Subject',
        kind: FieldKind.select,
        dynamicOptionsKey: 'subjects',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        dynamicOptionsKey: 'teachers',
      ),
      FormFieldSpec(
        name: 'meetingUrl',
        label: 'Meeting URL',
        kind: FieldKind.url,
      ),
      FormFieldSpec(
        name: 'time',
        label: 'Scheduled time',
        kind: FieldKind.date,
      ),
    ],
  ),
  ModuleSpec(
    key: 'settings',
    title: 'App Settings',
    route: '/admin/settings',
    icon: Icons.settings_rounded,
    goal: 'Configure school name, logo, language, and academic year.',
    group: 'Settings',
    columns: ['Setting', 'Value', 'Updated'],
    fields: [
      FormFieldSpec(name: 'schoolName', label: 'School name'),
      FormFieldSpec(
        name: 'language',
        label: 'Default language',
        kind: FieldKind.select,
        options: ['English', 'Arabic'],
      ),
      FormFieldSpec(name: 'academicYear', label: 'Academic year'),
    ],
    specialView: 'settings',
  ),
];

const teacherModules = <ModuleSpec>[
  ModuleSpec(
    key: 'teacher-dashboard',
    title: 'Dashboard',
    route: '/teacher/dashboard',
    icon: Icons.dashboard_rounded,
    goal: 'Teacher overview with schedule and quick actions.',
    columns: ['Item', 'Value'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'teacherDashboard',
  ),
  ModuleSpec(
    key: 'teacher-sections',
    title: 'Sections',
    route: '/teacher/sections',
    icon: Icons.grid_view_rounded,
    goal: 'Assigned sections with student counts.',
    columns: ['Section', 'Grade', 'Students'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
  ),
  ModuleSpec(
    key: 'teacher-students',
    title: 'Students',
    route: '/teacher/students',
    icon: Icons.school_rounded,
    goal: 'Students filtered to teacher sections.',
    columns: ['Name', 'Section', 'Attendance'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
  ),
  ModuleSpec(
    key: 'teacher-attendance',
    title: 'Attendance Reports',
    route: '/teacher/attendance-reports',
    icon: Icons.analytics_rounded,
    goal: 'Section/date selectors with attendance grid and export.',
    columns: ['Student', 'Present', 'Absent', 'Late'],
    fields: [],
    specialView: 'attendance',
    hasDelete: false,
  ),
  ModuleSpec(
    key: 'teacher-quizzes',
    title: 'Quizzes',
    route: '/teacher/quizzes',
    icon: Icons.quiz_rounded,
    goal: 'Teacher-created quizzes with draft/published status.',
    columns: ['Title', 'Subject', 'Status'],
    fields: [
      FormFieldSpec(name: 'title', label: 'Title'),
      FormFieldSpec(
        name: 'subject',
        label: 'Subject',
        kind: FieldKind.select,
        dynamicOptionsKey: 'subjects',
      ),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        dynamicOptionsKey: 'teachers',
      ),
      FormFieldSpec(
        name: 'timeLimit',
        label: 'Time limit',
        kind: FieldKind.number,
      ),
    ],
    specialView: 'quiz',
  ),
  ModuleSpec(
    key: 'teacher-questions',
    title: 'Questions',
    route: '/teacher/questions',
    icon: Icons.help_center_rounded,
    goal: 'Teacher question bank.',
    columns: ['Question', 'Type', 'Quiz'],
    fields: [
      FormFieldSpec(
        name: 'question',
        label: 'Question text',
        kind: FieldKind.multiline,
      ),
      FormFieldSpec(
        name: 'quiz',
        label: 'Quiz',
        kind: FieldKind.select,
        dynamicOptionsKey: 'quizzes',
      ),
    ],
  ),
  ModuleSpec(
    key: 'teacher-online',
    title: 'Online Classes',
    route: '/teacher/online-classes',
    icon: Icons.video_camera_front_rounded,
    goal: 'Teacher scheduled classes with meeting links.',
    columns: ['Title', 'Time', 'Link'],
    fields: [
      FormFieldSpec(name: 'title', label: 'Class title'),
      FormFieldSpec(
        name: 'grade',
        label: 'Grade',
        kind: FieldKind.select,
        dynamicOptionsKey: 'grades',
      ),
      FormFieldSpec(
        name: 'classroom',
        label: 'Classroom',
        kind: FieldKind.select,
        dynamicOptionsKey: 'classrooms',
      ),
      FormFieldSpec(
        name: 'section',
        label: 'Section',
        kind: FieldKind.select,
        dynamicOptionsKey: 'sections',
      ),
      FormFieldSpec(
        name: 'subject',
        label: 'Subject',
        kind: FieldKind.select,
        dynamicOptionsKey: 'subjects',
      ),
      FormFieldSpec(
        name: 'teacher',
        label: 'Teacher',
        kind: FieldKind.select,
        dynamicOptionsKey: 'teachers',
      ),
      FormFieldSpec(
        name: 'meetingUrl',
        label: 'Meeting link',
        kind: FieldKind.url,
      ),
    ],
  ),
  ModuleSpec(
    key: 'teacher-profile',
    title: 'Profile',
    route: '/teacher/profile',
    icon: Icons.person_rounded,
    goal: 'View and edit teacher info and password.',
    columns: ['Field', 'Value'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Name'),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
      ),
    ],
  ),
];

const studentModules = <ModuleSpec>[
  ModuleSpec(
    key: 'student-dashboard',
    title: 'Dashboard',
    route: '/student/dashboard',
    icon: Icons.dashboard_rounded,
    goal: 'Student overview with upcoming exams and grade summary.',
    columns: ['Item', 'Value'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'studentDashboard',
  ),
  ModuleSpec(
    key: 'student-exams',
    title: 'Available Exams',
    route: '/student/exams',
    icon: Icons.assignment_rounded,
    goal: 'Assigned exams with countdown and question flow.',
    columns: ['Exam', 'Countdown', 'Status'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'examFlow',
  ),
  ModuleSpec(
    key: 'student-profile',
    title: 'Profile',
    route: '/student/profile',
    icon: Icons.person_rounded,
    goal: 'View and edit student info and password.',
    columns: ['Field', 'Value'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Name'),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
      ),
    ],
  ),
];

const parentModules = <ModuleSpec>[
  ModuleSpec(
    key: 'parent-dashboard',
    title: 'Dashboard',
    route: '/parent/dashboard',
    icon: Icons.dashboard_rounded,
    goal: 'Children summary cards and recent alerts.',
    columns: ['Child', 'Grade', 'Alert'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'parentDashboard',
  ),
  ModuleSpec(
    key: 'parent-children',
    title: 'My Children',
    route: '/parent/children',
    icon: Icons.child_care_rounded,
    goal: 'Linked children with academic info.',
    columns: ['Name', 'Grade', 'Section'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
  ),
  ModuleSpec(
    key: 'parent-attendance',
    title: 'Attendance Report',
    route: '/parent/attendance',
    icon: Icons.event_available_rounded,
    goal: 'Child selector and color-coded attendance records.',
    columns: ['Date', 'Child', 'Status'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'attendance',
  ),
  ModuleSpec(
    key: 'parent-finance',
    title: 'Financial Report',
    route: '/parent/finance',
    icon: Icons.payments_rounded,
    goal: 'Fees and receipt history with download actions.',
    columns: ['Child', 'Amount', 'Status'],
    fields: [],
    hasCreate: false,
    hasEdit: false,
    hasDelete: false,
    specialView: 'financeTabs',
  ),
  ModuleSpec(
    key: 'parent-profile',
    title: 'Profile',
    route: '/parent/profile',
    icon: Icons.person_rounded,
    goal: 'View and edit parent info and password.',
    columns: ['Field', 'Value'],
    fields: [
      FormFieldSpec(name: 'name', label: 'Name'),
      FormFieldSpec(
        name: 'password',
        label: 'Password',
        kind: FieldKind.password,
      ),
    ],
  ),
];

List<ModuleSpec> modulesForRole(UserRole role) {
  return switch (role) {
    UserRole.admin => adminModules,
    UserRole.teacher => teacherModules,
    UserRole.student => studentModules,
    UserRole.parent => parentModules,
  };
}

const _primaryMobileKeys = <UserRole, List<String>>{
  UserRole.admin: [
    'admin-dashboard',
    'students',
    'attendance',
    'fees',
    'settings',
  ],
  UserRole.teacher: [
    'teacher-dashboard',
    'teacher-sections',
    'teacher-students',
    'teacher-attendance',
    'teacher-profile',
  ],
  UserRole.student: ['student-dashboard', 'student-exams', 'student-profile'],
  UserRole.parent: [
    'parent-dashboard',
    'parent-children',
    'parent-attendance',
    'parent-finance',
    'parent-profile',
  ],
};

List<ModuleSpec> primaryMobileModulesForRole(UserRole role) {
  final modules = modulesForRole(role);
  ModuleSpec find(String key) => modules.firstWhere(
    (module) => module.key == key,
    orElse: () => modules.first,
  );
  return [for (final key in _primaryMobileKeys[role]!) find(key)];
}

String defaultRouteForRole(UserRole role) {
  return modulesForRole(role).first.route;
}

List<NavGroup> navGroupsForRole(UserRole role) {
  final modules = modulesForRole(role);
  final grouped = <String, List<NavItem>>{};
  for (final module in modules) {
    grouped
        .putIfAbsent(module.group, () => [])
        .add(
          NavItem(label: module.title, icon: module.icon, route: module.route),
        );
  }
  return grouped.entries
      .map((entry) => NavGroup(label: entry.key, items: entry.value))
      .toList();
}

ModuleSpec? moduleByRoute(String route) {
  for (final module in [
    ...adminModules,
    ...teacherModules,
    ...studentModules,
    ...parentModules,
  ]) {
    if (module.route == route) return module;
  }
  return null;
}

ModuleSpec? moduleByKey(String key) {
  for (final module in [
    ...adminModules,
    ...teacherModules,
    ...studentModules,
    ...parentModules,
  ]) {
    if (module.key == key) return module;
  }
  return null;
}
