# Mobile App — Role-Based Navigation & API Contract

> **Version:** 1.0.0  
> **Purpose:** Single source of truth for the Flutter mobile app to build role-based navigation **without** the Admin portal.  
> **Last Updated:** 2026-06-24

---

## 1. Overview

The mobile app supports **3 user roles** (Admin is excluded from mobile):

| Role | Guard | Backend Model | Table |
|------|-------|---------------|-------|
| **Teacher** | `teacher` | `App\Models\Teacher` | `teachers` |
| **Student** | `student` | `App\Models\Student` | `students` |
| **Parent** | `parent` | `App\Models\My_Parent` | `my__parents` |

> **Note:** Admin features are **not available** in the mobile app. The role selection screen must only show **Teacher**, **Student**, and **Parent**.

---

## 2. Login API Response Shape

### 2.1 Endpoint

```
POST /auth/login
```

### 2.2 Request Body

```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

> The mobile app sends `email` and `password` only. The backend determines the user role by trying all 4 guards (`web`, `student`, `teacher`, `parent`) and returns the matching user.

### 2.3 Successful Response (200 OK)

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "1|laravel_sanctum_token_here_abc123",
    "token_type": "Bearer",
    "user": {
      "id": 42,
      "name": "Ahmed Hassan",
      "email": "ahmed.teacher@school.edu",
      "type": "teacher",
      "guard": "teacher"
    }
  }
}
```

### 2.4 Alternative Response Shape (also supported)

```json
{
  "access_token": "1|laravel_sanctum_token_here_abc123",
  "token": "1|laravel_sanctum_token_here_abc123",
  "token_type": "Bearer",
  "user": {
    "id": 42,
    "name": "Ahmed Hassan",
    "email": "ahmed.teacher@school.edu",
    "type": "teacher",
    "guard": "teacher"
  }
}
```

### 2.5 Role Determination Logic

The mobile app extracts the role from the login response using this priority:

1. `body['type']`
2. `body['guard']`
3. The role selected on the role-selection screen (fallback)

**Role mapping:**

| Backend Value | Mobile App Role |
|---------------|-----------------|
| `teacher` | `teacher` |
| `student` | `student` |
| `parent` | `parent` |
| `web` | `admin` (not used in mobile) |

---

## 3. User Profile API (`/me`)

### 3.1 Endpoint

```
POST /me
Authorization: Bearer <access_token>
```

### 3.2 Response Shape

```json
{
  "success": true,
  "data": {
    "user": {
      "id": 42,
      "name": "Ahmed Hassan",
      "email": "ahmed.teacher@school.edu",
      "type": "teacher",
      "guard": "teacher"
    }
  }
}
```

### 3.3 Alternative Response Shape

```json
{
  "id": 42,
  "name": "Ahmed Hassan",
  "email": "ahmed.teacher@school.edu",
  "type": "teacher",
  "guard": "teacher"
}
```

---

## 4. Role-Based Screens (Mobile App Modules)

### 4.1 Teacher Screens

| Screen Key | Title | Route | Icon | Description |
|------------|-------|-------|------|-------------|
| `teacher-dashboard` | Dashboard | `/teacher/dashboard` | `Icons.dashboard_rounded` | Teacher overview with schedule and quick actions |
| `teacher-sections` | Sections | `/teacher/sections` | `Icons.grid_view_rounded` | Assigned sections with student counts |
| `teacher-students` | Students | `/teacher/students` | `Icons.school_rounded` | Students filtered to teacher sections |
| `teacher-attendance` | Attendance Reports | `/teacher/attendance-reports` | `Icons.analytics_rounded` | Section/date selectors with attendance grid |
| `teacher-quizzes` | Quizzes | `/teacher/quizzes` | `Icons.quiz_rounded` | Teacher-created quizzes with draft/published status |
| `teacher-questions` | Questions | `/teacher/questions` | `Icons.help_center_rounded` | Teacher question bank |
| `teacher-online` | Online Classes | `/teacher/online-classes` | `Icons.video_camera_front_rounded` | Teacher scheduled classes with meeting links |
| `teacher-profile` | Profile | `/teacher/profile` | `Icons.person_rounded` | View and edit teacher info and password |

**Primary (Bottom Navigation) Screens:**
- Dashboard
- Sections
- Students
- Attendance Reports
- Profile

### 4.2 Student Screens

| Screen Key | Title | Route | Icon | Description |
|------------|-------|-------|------|-------------|
| `student-dashboard` | Dashboard | `/student/dashboard` | `Icons.dashboard_rounded` | Student overview with upcoming exams and grade summary |
| `student-exams` | Available Exams | `/student/exams` | `Icons.assignment_rounded` | Assigned exams with countdown and question flow |
| `student-profile` | Profile | `/student/profile` | `Icons.person_rounded` | View and edit student info and password |

**Primary (Bottom Navigation) Screens:**
- Dashboard
- Available Exams
- Profile

### 4.3 Parent Screens

| Screen Key | Title | Route | Icon | Description |
|------------|-------|-------|------|-------------|
| `parent-dashboard` | Dashboard | `/parent/dashboard` | `Icons.dashboard_rounded` | Children summary cards and recent alerts |
| `parent-children` | My Children | `/parent/children` | `Icons.child_care_rounded` | Linked children with academic info |
| `parent-attendance` | Attendance Report | `/parent/attendance` | `Icons.event_available_rounded` | Child selector and color-coded attendance records |
| `parent-finance` | Financial Report | `/parent/finance` | `Icons.payments_rounded` | Fees and receipt history with download actions |
| `parent-profile` | Profile | `/parent/profile` | `Icons.person_rounded` | View and edit parent info and password |

**Primary (Bottom Navigation) Screens:**
- Dashboard
- My Children
- Attendance Report
- Financial Report
- Profile

---

## 5. Complete Login Response Examples by Role

### 5.1 Teacher Login Response

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "1|laravel_sanctum_teacher_token_xyz789",
    "token_type": "Bearer",
    "user": {
      "id": 15,
      "name": "Ms. Sarah Johnson",
      "email": "sarah.johnson@school.edu",
      "type": "teacher",
      "guard": "teacher",
      "joining_date": "2023-09-01",
      "specialization": "Mathematics",
      "gender": "female",
      "address": "123 Education Street, Cityville"
    }
  }
}
```

### 5.2 Student Login Response

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "1|laravel_sanctum_student_token_abc456",
    "token_type": "Bearer",
    "user": {
      "id": 128,
      "name": "Omar Khaled",
      "email": "omar.khaled@student.school.edu",
      "type": "student",
      "guard": "student",
      "grade": "Grade 10",
      "classroom": "10-A",
      "section": "Section 1",
      "birth_date": "2008-05-15",
      "gender": "male",
      "academic_year": "2025-2026"
    }
  }
}
```

### 5.3 Parent Login Response

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "1|laravel_sanctum_parent_token_def012",
    "token_type": "Bearer",
    "user": {
      "id": 45,
      "name": "Mr. Khaled Ibrahim",
      "email": "khaled.ibrahim@email.com",
      "type": "parent",
      "guard": "parent",
      "father_name": "Khaled Ibrahim",
      "mother_name": "Fatima Ali",
      "phone": "+1234567890",
      "children": [
        {
          "id": 128,
          "name": "Omar Khaled",
          "grade": "Grade 10"
        },
        {
          "id": 130,
          "name": "Lina Khaled",
          "grade": "Grade 7"
        }
      ]
    }
  }
}
```

---

## 6. Mobile App Role Enum (Dart)

```dart
enum UserRole { teacher, student, parent }
```

> **Removed:** `admin` is intentionally excluded from the mobile enum.

### 6.1 Role Labels

```dart
const roleLabels = {
  UserRole.teacher: 'Teacher',
  UserRole.student: 'Student',
  UserRole.parent: 'Parent',
};
```

### 6.2 Role Icons

```dart
IconData iconForRole(UserRole role) {
  return switch (role) {
    UserRole.teacher => Icons.badge_rounded,
    UserRole.student => Icons.school_rounded,
    UserRole.parent => Icons.family_restroom_rounded,
  };
}
```

---

## 7. Role Selection Screen Changes

### 7.1 Filtered Roles List

```dart
// BEFORE (all 4 roles):
final roles = UserRole.values; // [admin, teacher, student, parent]

// AFTER (mobile only, no admin):
final roles = [UserRole.teacher, UserRole.student, UserRole.parent];
```

### 7.2 Role Selection UI

The role selection screen should display **3 cards** only:

1. **Teacher** — `Icons.badge_rounded` — "Manage classes, attendance, quizzes, and online sessions"
2. **Student** — `Icons.school_rounded` — "Take exams, view grades, and check schedule"
3. **Parent** — `Icons.family_restroom_rounded` — "Monitor children progress, attendance, and fees"

---

## 8. Navigation Logic

### 8.1 Home Route by Role

```dart
String defaultRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.teacher => '/teacher/dashboard',
    UserRole.student => '/student/dashboard',
    UserRole.parent => '/parent/dashboard',
  };
}
```

### 8.2 Module List by Role

```dart
List<ModuleSpec> modulesForRole(UserRole role) {
  return switch (role) {
    UserRole.teacher => teacherModules,
    UserRole.student => studentModules,
    UserRole.parent => parentModules,
  };
}
```

### 8.3 Primary (Bottom Nav) Screens by Role

```dart
const _primaryMobileKeys = <UserRole, List<String>>{
  UserRole.teacher: [
    'teacher-dashboard',
    'teacher-sections',
    'teacher-students',
    'teacher-attendance',
    'teacher-profile',
  ],
  UserRole.student: [
    'student-dashboard',
    'student-exams',
    'student-profile',
  ],
  UserRole.parent: [
    'parent-dashboard',
    'parent-children',
    'parent-attendance',
    'parent-finance',
    'parent-profile',
  ],
};
```

---

## 9. Backend Route Mapping (For Reference)

### 9.1 Teacher Backend Routes (`routes/teacher.php`)

| Route | Method | Description |
|-------|--------|-------------|
| `/teacher/dashboard` | GET | Teacher dashboard |
| `/student` | GET | View students in assigned sections |
| `/sections` | GET | View assigned sections |
| `/attendance` | POST | Record attendance |
| `/edit_attendance` | POST | Edit attendance |
| `/attendance_report` | GET/POST | View attendance reports |
| `/quizzes` | resource | CRUD quizzes |
| `/questions` | resource | CRUD questions |
| `/online_zoom_classes` | resource | CRUD online classes |
| `/indirect` | GET/POST | Indirect online class creation |
| `/profile` | GET/POST | View/update profile |
| `/student_quizze/{id}` | GET | View student quiz results |
| `/repeat_quizze` | POST | Allow student to retake quiz |

### 9.2 Student Backend Routes (`routes/student.php`)

| Route | Method | Description |
|-------|--------|-------------|
| `/student/dashboard` | GET | Student dashboard |
| `/student_exams` | resource | View and take exams |
| `/profile-student` | resource | View and update profile |

### 9.3 Parent Backend Routes (`routes/parent.php`)

| Route | Method | Description |
|-------|--------|-------------|
| `/parent/dashboard` | GET | Parent dashboard |
| `/children` | GET | View children list |
| `/results/{id}` | GET | View child results |
| `/attendances` | GET/POST | View child attendances |
| `/fees` | GET | View child fees |
| `/receipt/{id}` | GET | View child receipts |
| `/profile/parent` | GET/POST | View/update profile |

---

## 10. Error Handling

### 10.1 Invalid Credentials

```json
{
  "success": false,
  "message": "Invalid credentials",
  "errors": {
    "email": ["These credentials do not match our records."]
  }
}
```

### 10.2 Unauthorized (401)

```json
{
  "success": false,
  "message": "Unauthenticated."
}
```

### 10.3 Token Expired (401)

```json
{
  "success": false,
  "message": "Token has expired"
}
```

---

## 11. Implementation Checklist for Mobile App

- [ ] Remove `admin` from `UserRole` enum
- [ ] Update `RoleSelectionScreen` to show only 3 roles
- [ ] Update `modulesForRole()` to remove admin branch
- [ ] Update `defaultRouteForRole()` to remove admin branch
- [ ] Update `_primaryMobileKeys` to remove admin entry
- [ ] Ensure `AuthService._parseRole()` handles `teacher`, `student`, `parent` correctly
- [ ] Ensure `SessionController._parseRole()` handles `teacher`, `student`, `parent` correctly
- [ ] Update `AppShell` bottom navigation to use filtered role modules
- [ ] Test login flow for each role
- [ ] Verify navigation routes match backend routes

---

## 12. Quick Reference: Login → Role → Screens Flow

```
┌─────────────────┐
│  Role Selection │  (Teacher / Student / Parent)
│     Screen      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Login Screen   │  (email + password)
│   (role param)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  POST /login    │
│   API Call      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Parse Response  │
│  → Extract Role │  (from 'type' or 'guard' field)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Save Token +   │
│  User + Role    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Navigate to     │
│ Role Dashboard  │
└─────────────────┘
         │
    ┌────┴────┬────────┐
    ▼         ▼        ▼
┌────────┐ ┌────────┐ ┌────────┐
│Teacher │ │Student │ │ Parent │
│Dashboard│ │Dashboard│ │Dashboard│
└────────┘ └────────┘ └────────┘
```

---

## 13. File Locations to Modify

| File | Change |
|------|--------|
| `lib/core/models/app_models.dart` | Remove `admin` from `UserRole` enum |
| `lib/core/data/school_modules.dart` | Remove `adminModules`, update `modulesForRole()`, `defaultRouteForRole()`, `_primaryMobileKeys` |
| `lib/core/router/app_router.dart` | Remove `adminModules` from `allModules` list |
| `lib/core/network/auth_service.dart` | Update `_parseRole()` to handle only 3 roles |
| `lib/core/state/session_controller.dart` | Update `_parseRole()` to handle only 3 roles |
| `lib/features/auth/role_selection_screen.dart` | Filter `UserRole.values` to exclude admin |

---

*End of Document*
