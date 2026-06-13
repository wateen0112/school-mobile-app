import 'package:flutter/material.dart';

import '../data/school_modules.dart';
import '../models/app_models.dart';

bool appIsArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

String localizedRoleLabel(BuildContext context, UserRole role) {
  if (!appIsArabic(context)) return roleLabels[role] ?? role.name;
  return switch (role) {
    UserRole.admin => 'الإدارة',
    UserRole.teacher => 'المعلم',
    UserRole.student => 'الطالب',
    UserRole.parent => 'ولي الأمر',
  };
}

String localizedNavLabel(BuildContext context, NavItem item) {
  final module = moduleByRoute(item.route);
  if (module == null) return item.label;
  return localizedModuleTitle(context, module);
}

String localizedPageTitle(BuildContext context, String path) {
  final module = moduleByRoute(path);
  if (module != null) return localizedModuleTitle(context, module);
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  return parts.isEmpty ? 'Home' : parts.last.replaceAll('-', ' ');
}

String localizedModuleTitle(BuildContext context, ModuleSpec module) {
  if (!appIsArabic(context)) return module.title;
  return _moduleTitlesAr[module.key] ?? module.title;
}

String localizedModuleGoal(BuildContext context, ModuleSpec module) {
  if (!appIsArabic(context)) return module.goal;
  return _moduleGoalsAr[module.key] ?? module.goal;
}

String localizedGroupLabel(BuildContext context, String group) {
  if (!appIsArabic(context)) return group;
  return _groupsAr[group] ?? group;
}

String localizedColumnLabel(BuildContext context, String column) {
  if (!appIsArabic(context)) return column;
  return _columnsAr[column] ?? column;
}

String localizedFieldLabel(BuildContext context, FormFieldSpec field) {
  if (!appIsArabic(context)) return field.label;
  return _fieldsAr[field.label] ?? _extraFieldsAr[field.label] ?? field.label;
}

String localizedOptionLabel(BuildContext context, String option) {
  if (!appIsArabic(context)) return option;
  return _optionsAr[option] ?? option;
}

const _moduleTitlesAr = <String, String>{
  'admin-dashboard': 'لوحة التحكم',
  'grades': 'المراحل الدراسية',
  'classrooms': 'الفصول الدراسية',
  'sections': 'الأقسام',
  'students': 'الطلاب',
  'promotions': 'ترقيات الطلاب',
  'graduated': 'الطلاب المتخرجون',
  'teachers': 'المعلمون',
  'parents': 'أولياء الأمور',
  'fees': 'الرسوم',
  'invoices': 'الفواتير',
  'receipts': 'سندات القبض',
  'payments': 'المدفوعات',
  'attendance': 'الحضور',
  'attendance-history': 'سجل الحضور',
  'subjects': 'المواد الدراسية',
  'quizzes': 'الاختبارات',
  'questions': 'الأسئلة',
  'library': 'المكتبة',
  'online-classes': 'الحصص الإلكترونية',
  'settings': 'إعدادات التطبيق',
  'teacher-dashboard': 'لوحة المعلم',
  'teacher-sections': 'الأقسام',
  'teacher-students': 'الطلاب',
  'teacher-attendance': 'تقارير الحضور',
  'teacher-quizzes': 'اختباراتي',
  'teacher-questions': 'بنك الأسئلة',
  'teacher-online': 'الحصص الإلكترونية',
  'teacher-profile': 'الملف الشخصي',
  'student-dashboard': 'لوحة الطالب',
  'student-exams': 'الاختبارات المتاحة',
  'student-profile': 'الملف الشخصي',
  'parent-dashboard': 'لوحة ولي الأمر',
  'parent-children': 'أبنائي',
  'parent-attendance': 'تقرير الحضور',
  'parent-finance': 'التقرير المالي',
  'parent-profile': 'الملف الشخصي',
};

const _moduleGoalsAr = <String, String>{
  'admin-dashboard': 'نظرة إدارية عامة للإحصاءات والنشاطات والإجراءات السريعة.',
  'grades': 'إدارة المراحل الدراسية في المدرسة.',
  'classrooms': 'إنشاء وتنظيم الفصول حسب المرحلة.',
  'sections': 'إدارة الأقسام وربطها بالمعلمين.',
  'students': 'بحث وتصفية وإنشاء وتعديل سجلات الطلاب.',
  'promotions': 'ترقية مجموعة من الطلاب إلى مرحلة أو فصل جديد.',
  'graduated': 'أرشفة الطلاب المتخرجين والتصفية حسب سنة التخرج.',
  'teachers': 'إدارة بيانات المعلمين والمواد والصلاحيات.',
  'parents': 'إدارة حسابات أولياء الأمور وربط الأبناء.',
  'fees': 'متابعة الرسوم والمبالغ وتواريخ الاستحقاق وحالة الدفع.',
  'invoices': 'تصفية وإدارة الفواتير حسب التاريخ والحالة.',
  'receipts': 'عرض سندات القبض وإتاحتها للطباعة أو التحميل.',
  'payments': 'متابعة سجل المدفوعات والمعاملات المالية.',
  'attendance': 'تسجيل ومراجعة الحضور والغياب والتأخير.',
  'attendance-history':
      'عرض سجل الحضور فقط مع فلاتر المرحلة والفصل والقسم والتاريخ.',
  'subjects': 'إدارة المواد الدراسية وعلاقاتها بالمعلمين والفصول.',
  'quizzes': 'إدارة الاختبارات حسب المادة والقسم والتاريخ.',
  'questions': 'إنشاء أسئلة الاختيار من متعدد والصح والخطأ.',
  'library': 'إدارة الكتب والتصنيفات وحالة الإتاحة.',
  'online-classes': 'جدولة الحصص الإلكترونية وروابط الاجتماعات.',
  'settings': 'ضبط اسم المدرسة والشعار واللغة والسنة الدراسية.',
  'teacher-dashboard': 'ملخص جدول المعلم وروابط الإجراءات السريعة.',
  'teacher-sections': 'عرض الأقسام المسندة وعدد الطلاب.',
  'teacher-students': 'عرض طلاب الأقسام المسندة للمعلم.',
  'teacher-attendance': 'اختيار القسم والتاريخ ومراجعة الحضور.',
  'teacher-quizzes': 'إدارة اختبارات المعلم وحالات النشر.',
  'teacher-questions': 'إدارة بنك الأسئلة الخاص بالمعلم.',
  'teacher-online': 'جدولة حصص المعلم وروابط الاجتماعات.',
  'teacher-profile': 'عرض وتعديل بيانات المعلم وكلمة المرور.',
  'student-dashboard': 'ملخص اختبارات الطالب ودرجاته الحديثة.',
  'student-exams': 'عرض الاختبارات المتاحة والتنقل بين الأسئلة.',
  'student-profile': 'عرض وتعديل بيانات الطالب وكلمة المرور.',
  'parent-dashboard': 'ملخص الأبناء والتنبيهات الحديثة.',
  'parent-children': 'عرض بيانات الأبناء الأكاديمية.',
  'parent-attendance': 'متابعة حضور الأبناء بالألوان والحالات.',
  'parent-finance': 'عرض الرسوم وسجل السندات والمدفوعات.',
  'parent-profile': 'عرض وتعديل بيانات ولي الأمر وكلمة المرور.',
};

const _groupsAr = <String, String>{
  'Overview': 'نظرة عامة',
  'Grades': 'المراحل',
  'Classrooms': 'الفصول',
  'Sections': 'الأقسام',
  'Students': 'الطلاب',
  'Teachers': 'المعلمون',
  'Parents': 'أولياء الأمور',
  'Accounts': 'الحسابات',
  'Attendance': 'الحضور',
  'Subjects': 'المواد',
  'Exams': 'الاختبارات',
  'Library': 'المكتبة',
  'Online Classes': 'الحصص الإلكترونية',
  'Settings': 'الإعدادات',
  'General': 'عام',
};

const _columnsAr = <String, String>{
  'Metric': 'المؤشر',
  'Value': 'القيمة',
  'Trend': 'الاتجاه',
  'Grade name': 'اسم المرحلة',
  'Notes': 'ملاحظات',
  'Actions': 'الإجراءات',
  'Classroom': 'الفصل',
  'Grade': 'المرحلة',
  'Students': 'الطلاب',
  'Section': 'القسم',
  'Teacher': 'المعلم',
  'Status': 'الحالة',
  'Name': 'الاسم',
  'Subject': 'المادة',
  'Joining date': 'تاريخ الانضمام',
  'Parent': 'ولي الأمر',
  'Phone': 'الهاتف',
  'Children': 'الأبناء',
  'Student': 'الطالب',
  'Amount': 'المبلغ',
  'Due date': 'تاريخ الاستحقاق',
  'Invoice': 'الفاتورة',
  'Date': 'التاريخ',
  'Receipt': 'السند',
  'Download': 'تحميل',
  'Transaction': 'المعاملة',
  'Present': 'حاضر',
  'Absent': 'غائب',
  'Late': 'متأخر',
  'Title': 'العنوان',
  'Author': 'المؤلف',
  'Category': 'التصنيف',
  'Scheduled time': 'وقت الجدولة',
  'Link': 'الرابط',
  'Item': 'العنصر',
  'Attendance': 'الحضور',
  'Exam': 'الاختبار',
  'Countdown': 'العد التنازلي',
  'Field': 'الحقل',
  'Alert': 'التنبيه',
  'Child': 'الابن',
};

const _fieldsAr = <String, String>{
  'Grade name': 'اسم المرحلة',
  'Classroom name': 'اسم الفصل',
  'Section name': 'اسم القسم',
  'Teachers': 'المعلمون',
  'Student name': 'اسم الطالب',
  'Email': 'البريد الإلكتروني',
  'Birth date': 'تاريخ الميلاد',
  'Grade': 'المرحلة',
  'Section': 'القسم',
  'Linked parent': 'ولي الأمر المرتبط',
  'Students': 'الطلاب',
  'From grade': 'من المرحلة',
  'To grade': 'إلى المرحلة',
  'Promotion date': 'تاريخ الترقية',
  'Graduation year': 'سنة التخرج',
  'Notes': 'ملاحظات',
  'Teacher name': 'اسم المعلم',
  'Assigned subjects': 'المواد المسندة',
  'Password': 'كلمة المرور',
  'Father name': 'اسم الأب',
  'Mother name': 'اسم الأم',
  'Phone': 'الهاتف',
  'Linked children': 'الأبناء المرتبطون',
  'Student': 'الطالب',
  'Amount': 'المبلغ',
  'Due date': 'تاريخ الاستحقاق',
  'Status': 'الحالة',
  'Invoice date': 'تاريخ الفاتورة',
  'Question text': 'نص السؤال',
  'Type': 'النوع',
  'Answer options': 'خيارات الإجابة',
  'Correct answer': 'الإجابة الصحيحة',
  'Subject name': 'اسم المادة',
  'Book title': 'عنوان الكتاب',
  'Author': 'المؤلف',
  'Category': 'التصنيف',
  'Class title': 'عنوان الحصة',
  'Meeting URL': 'رابط الاجتماع',
  'Scheduled time': 'وقت الجدولة',
  'School name': 'اسم المدرسة',
  'Default language': 'اللغة الافتراضية',
  'Academic year': 'السنة الدراسية',
  'Title': 'العنوان',
  'Time limit': 'المدة الزمنية',
  'Meeting link': 'رابط الاجتماع',
  'Name': 'الاسم',
};

const _extraFieldsAr = <String, String>{
  'Classroom': 'الفصل',
  'Specialization': 'الاختصاص',
  'Gender': 'الجنس',
  'Nationality': 'الجنسية',
  'Blood type': 'فصيلة الدم',
  'Joining date': 'تاريخ الانضمام',
  'Address': 'العنوان',
  'Father national ID': 'الرقم الوطني للأب',
  'Subject': 'المادة',
  'Quiz': 'الاختبار',
  'Fee': 'الرسم',
  'From classroom': 'من الفصل',
  'To classroom': 'إلى الفصل',
  'From section': 'من القسم',
  'To section': 'إلى القسم',
};

const _optionsAr = <String, String>{
  'Primary': 'ابتدائي',
  'Middle': 'متوسط',
  'High': 'ثانوي',
  'A': 'أ',
  'B': 'ب',
  'C': 'ج',
  'Parent A': 'ولي أمر أ',
  'Parent B': 'ولي أمر ب',
  'Ahmed': 'أحمد',
  'Lana': 'لانا',
  'Omar': 'عمر',
  'Sara': 'سارة',
  'Mona': 'منى',
  'Math': 'الرياضيات',
  'Science': 'العلوم',
  'Arabic': 'العربية',
  'Paid': 'مدفوع',
  'Unpaid': 'غير مدفوع',
  'MCQ': 'اختيار من متعدد',
  'True/False': 'صح أو خطأ',
  'English': 'الإنجليزية',
};
