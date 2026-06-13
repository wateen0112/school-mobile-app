import 'package:flutter/material.dart';

import '../../widgets/shared_widgets.dart';
import '../data/school_repository.dart';
import '../localization/module_localization.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'confirmation_dialog.dart';

bool _isActionColumn(String column) {
  final lower = column.toLowerCase().trim();
  return lower == 'actions' || lower == 'action' || lower == 'download';
}

class SchoolDataTable extends StatefulWidget {
  const SchoolDataTable({
    super.key,
    required this.module,
    required this.rows,
    required this.records,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final List<List<String>> rows;
  final List<SchoolRecord> records;
  final VoidCallback onCreate;
  final ValueChanged<SchoolRecord> onEdit;
  final ValueChanged<SchoolRecord> onDelete;

  @override
  State<SchoolDataTable> createState() => _SchoolDataTableState();
}

class _SchoolDataTableState extends State<SchoolDataTable> {
  String _query = '';
  int _sortColumnIndex = 0;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final pairs =
        [
          for (
            var i = 0;
            i < widget.rows.length && i < widget.records.length;
            i++
          )
            (row: widget.rows[i], record: widget.records[i]),
        ].where((pair) {
          return pair.row
              .join(' ')
              .toLowerCase()
              .contains(_query.toLowerCase());
        }).toList();

    pairs.sort((a, b) {
      final left = _cell(a.row);
      final right = _cell(b.row);
      return _ascending ? left.compareTo(right) : right.compareTo(left);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableToolbar(
              module: widget.module,
              onCreate: widget.onCreate,
              onSearch: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            if (compact)
              _MobileRecordList(
                module: widget.module,
                pairs: pairs,
                onEdit: widget.onEdit,
                onDelete: _confirmDelete,
              )
            else
              _WideDataTable(
                module: widget.module,
                pairs: pairs,
                sortColumnIndex: _sortColumnIndex,
                ascending: _ascending,
                onSort: (index, ascending) => setState(() {
                  _sortColumnIndex = index;
                  _ascending = ascending;
                }),
                onEdit: widget.onEdit,
                onDelete: _confirmDelete,
              ),
          ],
        );
      },
    );
  }

  String _cell(List<String> row) {
    if (row.isEmpty) return '';
    final index = _sortColumnIndex.clamp(0, row.length - 1);
    return row[index];
  }

  Future<void> _confirmDelete(SchoolRecord record) async {
    final ok = await showConfirmationDialog(
      context,
      title: t(context, 'delete'),
      message: t(context, 'confirmDelete'),
      confirmLabel: t(context, 'delete'),
    );
    if (ok) widget.onDelete(record);
  }
}

class _TableToolbar extends StatelessWidget {
  const _TableToolbar({
    required this.module,
    required this.onCreate,
    required this.onSearch,
  });

  final ModuleSpec module;
  final VoidCallback onCreate;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final search = TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: t(context, 'search'),
          ),
          onChanged: onSearch,
        );
        final create = module.hasCreate
            ? FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: Text(t(context, 'create')),
              )
            : null;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              if (create != null) ...[const SizedBox(height: 10), create],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            if (create != null) ...[const SizedBox(width: 12), create],
          ],
        );
      },
    );
  }
}

class _MobileRecordList extends StatelessWidget {
  const _MobileRecordList({
    required this.module,
    required this.pairs,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final List<({List<String> row, SchoolRecord record})> pairs;
  final ValueChanged<SchoolRecord> onEdit;
  final ValueChanged<SchoolRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(t(context, 'noData'), textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: [
        for (final pair in pairs) ...[
          _MobileRecordCard(
            module: module,
            row: pair.row,
            record: pair.record,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MobileRecordCard extends StatelessWidget {
  const _MobileRecordCard({
    required this.module,
    required this.row,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final List<String> row;
  final SchoolRecord record;
  final ValueChanged<SchoolRecord> onEdit;
  final ValueChanged<SchoolRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (module.key == 'students') {
      return _StudentRecordCard(
        module: module,
        row: row,
        record: record,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }

    final title = row.isNotEmpty
        ? row.first
        : localizedModuleTitle(context, module);
    final details = <({String label, String value})>[
      for (var i = 1; i < module.columns.length && i < row.length; i++)
        if (!_isActionColumn(module.columns[i]))
          (
            label: localizedColumnLabel(context, module.columns[i]),
            value: row[i],
          ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(module.icon, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _RecordActions(
                  module: module,
                  onEdit: () => onEdit(record),
                  onDelete: () => onDelete(record),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final detail in details)
                    _DetailPill(label: detail.label, value: detail.value),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentRecordCard extends StatelessWidget {
  const _StudentRecordCard({
    required this.module,
    required this.row,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final List<String> row;
  final SchoolRecord record;
  final ValueChanged<SchoolRecord> onEdit;
  final ValueChanged<SchoolRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final title = row.isNotEmpty
        ? row[0]
        : localizedModuleTitle(context, module);
    final grade = row.length > 1 ? row[1] : '-';
    final section = row.length > 2 ? row[2] : '-';
    final email = row.length > 3 ? row[3] : '-';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _showStudentDetails(context, record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _RecordActions(
                    module: module,
                    onEdit: () => onEdit(record),
                    onDelete: () => onDelete(record),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DetailPill(
                      label: localizedColumnLabel(context, 'Grade'),
                      value: grade,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailPill(
                      label: localizedColumnLabel(context, 'Section'),
                      value: section,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, SchoolRecord record) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (context) => _StudentDetailsSheet(record: record),
    );
  }
}

class _StudentDetailsSheet extends StatelessWidget {
  const _StudentDetailsSheet({required this.record});

  final SchoolRecord record;

  @override
  Widget build(BuildContext context) {
    final raw = record.raw;
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = _display(raw['name'] ?? raw['Name'], languageCode);
    final email = _display(raw['email'] ?? raw['Email'], languageCode);
    final grade = _display(raw['grade'] ?? raw['Grade_id'], languageCode);
    final classroom = _display(
      raw['classroom'] ?? raw['Classroom_id'],
      languageCode,
    );
    final section = _display(raw['section'] ?? raw['section_id'], languageCode);
    final parent = _display(raw['myparent'] ?? raw['parent'], languageCode);
    final birthDate = _display(raw['Date_Birth'], languageCode);
    final academicYear = _display(raw['academic_year'], languageCode);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 14,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .82,
          ),
          decoration: AppTheme.softPanel(radius: 30),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.ctaGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email == '-' ? '' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _StudentDetailRow(
                  icon: Icons.layers_rounded,
                  label: localizedColumnLabel(context, 'Grade'),
                  value: grade,
                ),
                _StudentDetailRow(
                  icon: Icons.meeting_room_rounded,
                  label: localizedColumnLabel(context, 'Classroom'),
                  value: classroom,
                ),
                _StudentDetailRow(
                  icon: Icons.groups_rounded,
                  label: localizedColumnLabel(context, 'Section'),
                  value: section,
                ),
                _StudentDetailRow(
                  icon: Icons.family_restroom_rounded,
                  label: appIsArabic(context) ? 'ولي الأمر' : 'Parent',
                  value: parent,
                ),
                _StudentDetailRow(
                  icon: Icons.cake_rounded,
                  label: appIsArabic(context) ? 'تاريخ الميلاد' : 'Birth date',
                  value: birthDate,
                ),
                _StudentDetailRow(
                  icon: Icons.event_available_rounded,
                  label: appIsArabic(context)
                      ? 'السنة الدراسية'
                      : 'Academic year',
                  value: academicYear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _display(dynamic value, String languageCode) {
    final text = displayValue(value, languageCode: languageCode).trim();
    return text.isEmpty ? '-' : text;
  }
}

class _StudentDetailRow extends StatelessWidget {
  const _StudentDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordActions extends StatelessWidget {
  const _RecordActions({
    required this.module,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t(context, 'edit'),
          onPressed: module.hasEdit ? onEdit : null,
          icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
        ),
        IconButton(
          tooltip: t(context, 'delete'),
          onPressed: module.hasDelete ? onDelete : null,
          icon: const Icon(Icons.delete_rounded, color: AppTheme.coral),
        ),
      ],
    );
  }
}

class _WideDataTable extends StatelessWidget {
  const _WideDataTable({
    required this.module,
    required this.pairs,
    required this.sortColumnIndex,
    required this.ascending,
    required this.onSort,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleSpec module;
  final List<({List<String> row, SchoolRecord record})> pairs;
  final int sortColumnIndex;
  final bool ascending;
  final void Function(int index, bool ascending) onSort;
  final ValueChanged<SchoolRecord> onEdit;
  final ValueChanged<SchoolRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            AppTheme.primary.withValues(alpha: .08),
          ),
          dataRowMinHeight: 62,
          dataRowMaxHeight: 70,
          headingTextStyle: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
          dataTextStyle: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w600,
          ),
          sortColumnIndex: sortColumnIndex,
          sortAscending: ascending,
          columns: [
            for (var i = 0; i < module.columns.length; i++)
              if (!_isActionColumn(module.columns[i]))
                DataColumn(
                  label: Text(localizedColumnLabel(context, module.columns[i])),
                  onSort: onSort,
                ),
            DataColumn(label: Text(t(context, 'actions'))),
          ],
          rows: [
            for (final pair in pairs)
              DataRow(
                cells: [
                  for (
                    var i = 0;
                    i < module.columns.length && i < pair.row.length;
                    i++
                  )
                    if (!_isActionColumn(module.columns[i]))
                      DataCell(Text(pair.row[i])),
                  DataCell(
                    _RecordActions(
                      module: module,
                      onEdit: () => onEdit(pair.record),
                      onDelete: () => onDelete(pair.record),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
