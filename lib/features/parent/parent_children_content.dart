import 'package:flutter/material.dart';

import '../../core/data/school_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'child_details_screen.dart';

class ParentChildrenContent extends StatelessWidget {
  const ParentChildrenContent({super.key, required this.records});

  final List<SchoolRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              t(context, 'noData'),
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final record in records) ...[
          _ChildCard(record: record),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.record});

  final SchoolRecord record;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final raw = record.raw;
    final name = displayValue(
      raw['name'] ?? raw['Name'],
      languageCode: languageCode,
    );
    final email = raw['email']?.toString() ?? '';
    final grade = displayValue(raw['grade'], languageCode: languageCode);
    final classroom = displayValue(
      raw['classroom'],
      languageCode: languageCode,
    );
    final section = displayValue(raw['section'], languageCode: languageCode);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChildDetailsScreen(
                childId: record.id ?? 0,
                childRaw: raw,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(context, Icons.school_rounded, grade),
                        _chip(context, Icons.meeting_room_rounded, classroom),
                        _chip(context, Icons.groups_rounded, section),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}