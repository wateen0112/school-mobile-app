import 'package:flutter/material.dart';

import '../app/api_client.dart';
import '../app/design_system.dart';
import '../app/resource_registry.dart';
import '../widgets/shared_widgets.dart';
import 'resource_form_screen.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({
    super.key,
    required this.api,
    required this.definition,
  });

  final SchoolApiClient api;
  final ResourceDefinition definition;

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  String _query = '';
  late Future<List<dynamic>> _future = widget.api.list(
    widget.definition.endpoint,
  );

  void _reload() {
    setState(() => _future = widget.api.list(widget.definition.endpoint));
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: t(context, widget.definition.titleKey),
      floatingActionButton: widget.definition.canWrite
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: Text(t(context, 'add')),
            )
          : null,
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: t(context, 'search'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.wifi_off_rounded,
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final items = (snapshot.data ?? const []).where((item) {
                  if (_query.isEmpty) return true;
                  return displayValue(
                    item,
                    languageCode: Localizations.localeOf(context).languageCode,
                  ).toLowerCase().contains(_query);
                }).toList();
                if (items.isEmpty) {
                  return EmptyState(
                    icon: widget.definition.icon,
                    message: t(context, 'noData'),
                    onRetry: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _ResourceTile(
                      item: items[index],
                      definition: widget.definition,
                      onEdit: widget.definition.canWrite
                          ? () => _openForm(items[index])
                          : null,
                      onDelete: widget.definition.canWrite
                          ? () => _delete(items[index])
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm([dynamic item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResourceFormScreen(
          api: widget.api,
          definition: widget.definition,
          item: item is Map<String, dynamic> ? item : null,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(dynamic item) async {
    final id = item is Map ? item['id'] : null;
    if (id is! int) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'delete')),
        content: Text(t(context, 'confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(context, 'cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.api.delete(widget.definition.endpoint, id);
    _reload();
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.item,
    required this.definition,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic item;
  final ResourceDefinition definition;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item as Map : const {};
    final lang = Localizations.localeOf(context).languageCode;
    final title = _pickTitle(map, lang);
    final subtitle = definition.subtitleKeys
        .map((key) => displayValue(map[key], languageCode: lang))
        .where((value) => value.isNotEmpty)
        .join(' • ');

    return SoftCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SchoolColors.cardBlue.withValues(alpha: .18),
            foregroundColor: SchoolColors.primary,
            child: Icon(definition.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? t(context, definition.titleKey) : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: SchoolColors.muted),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                enabled: onEdit != null,
                child: Text(t(context, 'edit')),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: onDelete != null,
                child: Text(t(context, 'delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pickTitle(Map<dynamic, dynamic> map, String lang) {
    for (final key in [
      'name',
      'Name',
      'title',
      'Name_Class',
      'Name_Section',
      'school_name',
      'email',
      'Email',
    ]) {
      final value = displayValue(map[key], languageCode: lang);
      if (value.isNotEmpty) return value;
    }
    return displayValue(map, languageCode: lang);
  }
}
