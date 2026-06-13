import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/resource_registry.dart';
import '../widgets/shared_widgets.dart';

class ResourceFormScreen extends StatefulWidget {
  const ResourceFormScreen({
    super.key,
    required this.api,
    required this.definition,
    this.item,
  });

  final SchoolApiClient api;
  final ResourceDefinition definition;
  final Map<String, dynamic>? item;

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    for (final field in widget.definition.fields) {
      _controllers[field.key] = TextEditingController(
        text: displayValue(widget.item?[field.key], languageCode: lang),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = <String, dynamic>{};
    for (final field in widget.definition.fields) {
      final raw = _controllers[field.key]!.text.trim();
      if (raw.isEmpty) continue;
      data[field.key] = switch (field.type) {
        FieldType.number => num.tryParse(raw) ?? raw,
        FieldType.numberList =>
          raw
              .split(',')
              .map((item) => int.tryParse(item.trim()))
              .whereType<int>()
              .toList(),
        _ => raw,
      };
    }
    try {
      final id = widget.item?['id'];
      if (id is int) {
        await widget.api.update(widget.definition.endpoint, id, data);
      } else {
        await widget.api.create(widget.definition.endpoint, data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return AppPage(
      title:
          '${isEditing ? t(context, 'edit') : t(context, 'add')} ${t(context, widget.definition.titleKey)}',
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            for (final field in widget.definition.fields) ...[
              TextFormField(
                controller: _controllers[field.key],
                minLines: field.type == FieldType.multiline ? 3 : 1,
                maxLines: field.type == FieldType.multiline ? 5 : 1,
                obscureText: field.type == FieldType.password,
                keyboardType: _keyboardType(field.type),
                decoration: InputDecoration(
                  labelText: t(context, field.labelKey),
                ),
                validator: field.required
                    ? (value) => value == null || value.trim().isEmpty
                          ? t(context, field.labelKey)
                          : null
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            GradientButton(
              label: t(context, 'save'),
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  TextInputType _keyboardType(FieldType type) {
    return switch (type) {
      FieldType.email => TextInputType.emailAddress,
      FieldType.number => TextInputType.number,
      FieldType.numberList => TextInputType.text,
      FieldType.date => TextInputType.datetime,
      FieldType.multiline => TextInputType.multiline,
      _ => TextInputType.text,
    };
  }
}
