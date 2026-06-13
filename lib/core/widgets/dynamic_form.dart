import 'package:flutter/material.dart';

import '../localization/module_localization.dart';
import '../models/app_models.dart';

class DynamicModuleForm extends StatefulWidget {
  const DynamicModuleForm({
    super.key,
    required this.module,
    required this.submitLabel,
    required this.onSubmit,
    this.topPadding = 0,
    this.initialValues,
    this.fieldOptions = const {},
  });

  final ModuleSpec module;
  final String submitLabel;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final double topPadding;
  final Map<String, dynamic>? initialValues;
  final Map<String, List<FormOption>> fieldOptions;

  @override
  State<DynamicModuleForm> createState() => _DynamicModuleFormState();
}

class _DynamicModuleFormState extends State<DynamicModuleForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selectValues = <String, dynamic>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.module.fields) {
      final initial = _initialValue(field);
      if (field.kind == FieldKind.select) {
        final options = _optionsFor(field);
        _selectValues[field.name] =
            options.any((option) => option.value == initial) ? initial : null;
      } else if (field.kind == FieldKind.multiSelect) {
        final options = _optionsFor(field);
        final initialList = _initialList(field);
        _selectValues[field.name] = initialList
            .where(
              (value) => options.any((option) => option.value == value),
            )
            .toList();
      } else {
        _controllers[field.name] = TextEditingController(text: initial ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16 + widget.topPadding, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final field in widget.module.fields) ...[
                _FieldInput(
                  field: field,
                  options: _optionsFor(field),
                  controller: _controllers[field.name],
                  value: _selectValues[field.name],
                  onChanged: (value) =>
                      setState(() => _selectValues[field.name] = value),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _submitting = true);
                          try {
                            await widget.onSubmit(_values);
                          } finally {
                            if (mounted) setState(() => _submitting = false);
                          }
                        }
                      },
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> get _values {
    return {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      for (final entry in _selectValues.entries)
        if (entry.value is List
            ? (entry.value as List).isNotEmpty
            : entry.value != null)
          entry.key: entry.value,
    };
  }

  String? _initialValue(FormFieldSpec field) {
    final raw = widget.initialValues;
    if (raw == null) return null;
    final candidates = [
      field.name,
      field.label,
      if (field.name == 'grade') 'Grade_id',
      if (field.name == 'classroom') 'Classroom_id',
      if (field.name == 'classroom') 'Class_id',
      if (field.name == 'section') 'section_id',
      if (field.name == 'teacher') 'teacher_id',
      if (field.name == 'student') 'student_id',
      if (field.name == 'parent') 'parent_id',
      if (field.name == 'subject') 'subject_id',
      if (field.name == 'quiz') 'quizze_id',
      if (field.name == 'fee') 'fee_id',
      if (field.name == 'specialization') 'Specialization_id',
      if (field.name == 'gender') 'Gender_id',
      if (field.name == 'nationality') 'nationalitie_id',
      if (field.name == 'bloodType') 'blood_id',
      if (field.name == 'fatherName') 'Father_Name',
      if (field.name == 'fatherNationalId') 'Father_National_ID',
      field.name.replaceAll('Date', '_date'),
      'Name',
      'name',
      'title',
    ];
    for (final key in candidates) {
      final value = raw[key];
      if (value == null) continue;
      if (value is List) {
        return value.isEmpty ? null : '${value.first}';
      }
      if (value is Map) {
        return '${value['en'] ?? value['ar'] ?? (value.values.isEmpty ? '' : value.values.first)}';
      }
      return '$value';
    }
    return null;
  }

  List<String> _initialList(FormFieldSpec field) {
    final raw = widget.initialValues;
    if (raw == null) return [];
    final value = raw[field.name];
    if (value is List) {
      return value
          .map((item) => '$item')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value != null) return ['$value'];
    return [];
  }

  List<FormOption> _optionsFor(FormFieldSpec field) {
    final dynamicOptions = widget.fieldOptions[field.name];
    if (dynamicOptions != null) return dynamicOptions;
    return [
      for (final option in field.options)
        FormOption(value: option, label: option),
    ];
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.field,
    required this.options,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final FormFieldSpec field;
  final List<FormOption> options;
  final TextEditingController? controller;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    if (field.kind == FieldKind.select) {
      final hasDynamicOptions = field.dynamicOptionsKey != null;
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: localizedFieldLabel(context, field),
          helperText: hasDynamicOptions && options.isEmpty
              ? (appIsArabic(context)
                    ? 'تعذر تحميل الخيارات، تحقق من الاتصال أو الـ API'
                    : 'Options could not be loaded. Check connection or API.')
              : null,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option.value,
                child: Text(localizedOptionLabel(context, option.label)),
              ),
            )
            .toList(),
        initialValue: value is String ? value as String : null,
        onChanged: (selected) => onChanged(selected),
        validator: field.required
            ? (value) => value == null
                  ? appIsArabic(context)
                        ? '${localizedFieldLabel(context, field)} مطلوب'
                        : '${field.label} is required'
                  : null
            : null,
      );
    }
    if (field.kind == FieldKind.multiSelect) {
      final hasDynamicOptions = field.dynamicOptionsKey != null;
      final selected = value is List<String> ? value as List<String> : <String>[];
      return _MultiSelectDropdown(
        field: field,
        options: options,
        selectedValues: selected,
        hasDynamicOptions: hasDynamicOptions,
        onChanged: onChanged,
      );
    }
    if (field.kind == FieldKind.date) {
      final dateController = controller;
      if (dateController == null) return const SizedBox.shrink();
      return TextFormField(
        controller: dateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: localizedFieldLabel(context, field),
          suffixIcon: const Icon(Icons.calendar_month_rounded),
        ),
        onTap: () async {
          final now = DateTime.now();
          final initialDate = DateTime.tryParse(dateController.text) ?? now;
          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(now.year - 80),
            lastDate: DateTime(now.year + 20),
            locale: Localizations.localeOf(context),
          );
          if (picked == null) return;
          dateController.text = _formatDate(picked);
        },
        validator: field.required
            ? (value) => value == null || value.trim().isEmpty
                  ? appIsArabic(context)
                        ? '${localizedFieldLabel(context, field)} مطلوب'
                        : '${field.label} is required'
                  : null
            : null,
      );
    }
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: localizedFieldLabel(context, field),
      ),
      minLines: field.kind == FieldKind.multiline ? 4 : 1,
      maxLines: field.kind == FieldKind.multiline ? 6 : 1,
      obscureText: field.kind == FieldKind.password,
      keyboardType: switch (field.kind) {
        FieldKind.email => TextInputType.emailAddress,
        FieldKind.number => TextInputType.number,
        FieldKind.date => TextInputType.datetime,
        FieldKind.url => TextInputType.url,
        FieldKind.multiline => TextInputType.multiline,
        _ => TextInputType.text,
      },
      validator: field.required
          ? (value) => value == null || value.trim().isEmpty
                ? appIsArabic(context)
                      ? '${localizedFieldLabel(context, field)} مطلوب'
                      : '${field.label} is required'
                : null
          : null,
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

class _MultiSelectDropdown extends StatelessWidget {
  const _MultiSelectDropdown({
    required this.field,
    required this.options,
    required this.selectedValues,
    required this.hasDynamicOptions,
    required this.onChanged,
  });

  final FormFieldSpec field;
  final List<FormOption> options;
  final List<String> selectedValues;
  final bool hasDynamicOptions;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final helperText = hasDynamicOptions && options.isEmpty
        ? (isArabic
              ? 'تعذر تحميل الخيارات، تحقق من الاتصال أو الـ API'
              : 'Options could not be loaded. Check connection or API.')
        : null;
    final errorText = field.required && selectedValues.isEmpty
        ? (isArabic
              ? '${localizedFieldLabel(context, field)} مطلوب'
              : '${field.label} is required')
        : null;
    final hint = isArabic ? 'اختر...' : 'Select...';

    String labelFor(String value) {
      final option = options.firstWhere(
        (option) => option.value == value,
        orElse: () => FormOption(value: value, label: value),
      );
      return option.label;
    }

    return InkWell(
      onTap: options.isEmpty
          ? null
          : () async {
              final updated = await showDialog<List<String>>(
                context: context,
                builder: (context) {
                  final tempSelected = List<String>.from(selectedValues);
                  return AlertDialog(
                    title: Text(localizedFieldLabel(context, field)),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              return CheckboxListTile(
                                title: Text(
                                  localizedOptionLabel(
                                    context,
                                    option.label,
                                  ),
                                ),
                                value: tempSelected.contains(option.value),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      tempSelected.add(option.value);
                                    } else {
                                      tempSelected.remove(option.value);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, tempSelected),
                        child: Text(isArabic ? 'تأكيد' : 'OK'),
                      ),
                    ],
                  );
                },
              );
              if (updated != null) {
                onChanged(updated);
              }
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: localizedFieldLabel(context, field),
          helperText: helperText,
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selectedValues.isEmpty
            ? Text(
                hint,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final value in selectedValues)
                    Chip(
                      label: Text(
                        localizedOptionLabel(context, labelFor(value)),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
      ),
    );
  }
}
