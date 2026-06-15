import 'package:flutter/material.dart';

import '../../core/data/school_repository.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../widgets/shared_widgets.dart';

class ModuleViewModel extends ChangeNotifier {
  ModuleViewModel({required this.module, required SchoolRepository repository})
    : _repository = repository {
    load();
  }

  final ModuleSpec module;
  final SchoolRepository _repository;

  bool loading = true;
  bool saving = false;
  String? error;
  bool empty = false;
  List<SchoolRecord> records = const [];
  Map<String, dynamic>? dashboardData;
  bool filterOptionsLoading = false;
  String? selectedGradeId;
  String? selectedSectionId;
  List<FormOption> gradeFilterOptions = const [];
  List<FormOption> sectionFilterOptions = const [];
  bool _disposed = false;
  String? _filterLanguageCode;
  bool _studentFiltersLoaded = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      if (module.specialView == 'dashboard') {
        dashboardData = await _repository.dashboard();
        records = const [];
      } else {
        records = module.key == 'students'
            ? await _repository.filteredStudents(
                gradeId: selectedGradeId,
                sectionId: selectedSectionId,
              )
            : await _repository.list(module);
      }
      empty = records.isEmpty && module.specialView == null;
    } catch (e) {
      final failure = ApiService.failureFrom(e);
      error = failure.message;
      records = const [];
      empty = false;
    } finally {
      if (!_disposed) {
        loading = false;
        _notify();
      }
    }
  }

  List<List<String>> rowsFor(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return records
        .map(
          (record) =>
              _repository.rowFor(module, record, languageCode: languageCode),
        )
        .toList();
  }

  Future<void> create(Map<String, dynamic> values) async {
    saving = true;
    error = null;
    _notify();
    try {
      await _repository.create(module, values);
      await load();
    } catch (e) {
      error = ApiService.failureFrom(e).message;
      rethrow;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> update(SchoolRecord record, Map<String, dynamic> values) async {
    saving = true;
    error = null;
    _notify();
    try {
      await _repository.update(module, record, values);
      await load();
    } catch (e) {
      error = ApiService.failureFrom(e).message;
      rethrow;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> delete(SchoolRecord record) async {
    saving = true;
    error = null;
    _notify();
    try {
      await _repository.delete(module, record);
      await load();
    } catch (e) {
      error = ApiService.failureFrom(e).message;
      rethrow;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> ensureStudentFilters(String languageCode) async {
    if (module.key != 'students') return;
    if (filterOptionsLoading) return;
    if (_filterLanguageCode == languageCode && _studentFiltersLoaded) {
      return;
    }

    _filterLanguageCode = languageCode;
    filterOptionsLoading = true;
    _notify();
    try {
      gradeFilterOptions = await _repository.optionsFor(
        'grades',
        languageCode: languageCode,
      );
      _studentFiltersLoaded = true;
      if (selectedGradeId != null && selectedGradeId!.isNotEmpty) {
        sectionFilterOptions = await _repository.sectionsForGrade(
          selectedGradeId!,
          languageCode: languageCode,
        );
      }
    } catch (e) {
      error = ApiService.failureFrom(e).message;
    } finally {
      filterOptionsLoading = false;
      _notify();
    }
  }

  Future<void> setStudentGrade(String? gradeId, String languageCode) async {
    selectedGradeId = gradeId?.isEmpty == true ? null : gradeId;
    selectedSectionId = null;
    sectionFilterOptions = const [];
    filterOptionsLoading = true;
    _notify();
    try {
      if (selectedGradeId != null) {
        sectionFilterOptions = await _repository.sectionsForGrade(
          selectedGradeId!,
          languageCode: languageCode,
        );
      }
      await load();
    } catch (e) {
      error = ApiService.failureFrom(e).message;
    } finally {
      filterOptionsLoading = false;
      _notify();
    }
  }

  Future<void> setStudentSection(String? sectionId) async {
    selectedSectionId = sectionId?.isEmpty == true ? null : sectionId;
    await load();
  }

  Future<void> clearStudentFilters() async {
    selectedGradeId = null;
    selectedSectionId = null;
    sectionFilterOptions = const [];
    await load();
  }

  void showSaved(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t(context, 'savedSuccessfully'))));
  }

  Future<Map<String, List<FormOption>>> formOptions(
    BuildContext context,
  ) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final dynamicFields = module.fields.where(
      (field) => field.dynamicOptionsKey != null,
    );
    final entries = await Future.wait(
      dynamicFields.map((field) async {
        try {
          final options = await _repository.optionsFor(
            field.dynamicOptionsKey!,
            languageCode: languageCode,
          );
          return MapEntry(field.name, options);
        } catch (error, stackTrace) {
          debugPrint(
            '[ModuleViewModel] Failed to load options for "${field.name}" '
            '(key: ${field.dynamicOptionsKey}): $error\n$stackTrace',
          );
          rethrow;
        }
      }),
    );
    return Map.fromEntries(entries);
  }
}
