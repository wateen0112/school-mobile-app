import 'package:flutter/material.dart';

enum UserRole { admin, teacher, student, parent }

enum FieldKind {
  text,
  email,
  password,
  number,
  date,
  multiline,
  select,
  multiSelect,
  url,
}

class AppUser {
  const AppUser({required this.name, required this.email, required this.role});

  final String name;
  final String email;
  final UserRole role;
}

class NavItem {
  const NavItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

class NavGroup {
  const NavGroup({required this.label, required this.items});

  final String label;
  final List<NavItem> items;
}

class FormFieldSpec {
  const FormFieldSpec({
    required this.name,
    required this.label,
    this.kind = FieldKind.text,
    this.required = false,
    this.options = const [],
    this.dynamicOptionsKey,
  });

  final String name;
  final String label;
  final FieldKind kind;
  final bool required;
  final List<String> options;
  final String? dynamicOptionsKey;
}

class FormOption {
  const FormOption({required this.value, required this.label});

  final String value;
  final String label;
}

class ModuleSpec {
  const ModuleSpec({
    required this.key,
    required this.title,
    required this.route,
    required this.icon,
    required this.goal,
    required this.columns,
    required this.fields,
    this.group = 'General',
    this.hasCreate = true,
    this.hasEdit = true,
    this.hasDelete = true,
    this.specialView,
  });

  final String key;
  final String title;
  final String route;
  final IconData icon;
  final String goal;
  final List<String> columns;
  final List<FormFieldSpec> fields;
  final String group;
  final bool hasCreate;
  final bool hasEdit;
  final bool hasDelete;
  final String? specialView;
}
