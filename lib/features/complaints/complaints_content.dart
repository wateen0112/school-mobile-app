import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/confirmation_dialog.dart';

class ComplaintsContent extends StatefulWidget {
  const ComplaintsContent({super.key});

  @override
  State<ComplaintsContent> createState() => _ComplaintsContentState();
}

class _ComplaintsContentState extends State<ComplaintsContent> {
  late final ApiService _api;
  List<dynamic> _complaints = [];
  bool _loading = true;
  String? _error;

  // Form state
  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'normal';
  bool _saving = false;

  // File picker
  List<File> _selectedFiles = [];
  bool _showFilePicker = false;

  // Detail view
  dynamic _selectedComplaint;
  bool _detailLoading = false;

  // Reply state
  final _replyCtrl = TextEditingController();
  List<File> _replyFiles = [];
  bool _sendingReply = false;

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComplaints());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() { _loading = true; _error = null; });
    try {
      final body = await _api.get('/complaints');
      final data = body['data'];
      if (mounted) setState(() {
        _complaints = (data is List) ? data : [];
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  Future<void> _loadDetail(int id) async {
    setState(() { _detailLoading = true; });
    try {
      final body = await _api.get('/complaints/$id');
      if (mounted) setState(() {
        _selectedComplaint = body['data'];
        _detailLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _detailLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.failureFrom(error).message)),
        );
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final formData = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'priority': _priority,
      });
      for (final file in _selectedFiles) {
        formData.files.add(MapEntry(
          'files[]',
          await MultipartFile.fromFile(file.path, filename: file.path.split('\\').last),
        ));
      }
      await _api.multipart('/complaints', formData: formData);
      if (mounted) {
        setState(() {
          _saving = false;
          _showForm = false;
          _titleCtrl.clear();
          _descCtrl.clear();
          _priority = 'normal';
          _selectedFiles = [];
        });
        _loadComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'complaintSubmitted')),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t(context, 'errorPrefix')}${ApiService.failureFrom(error).message}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    if (_selectedComplaint == null) return;
    setState(() => _sendingReply = true);
    try {
      final formData = FormData.fromMap({
        'message': _replyCtrl.text.trim(),
      });
      for (final file in _replyFiles) {
        formData.files.add(MapEntry(
          'files[]',
          await MultipartFile.fromFile(file.path, filename: file.path.split('\\').last),
        ));
      }
      await _api.multipart('/complaints/${_selectedComplaint['id']}/reply', formData: formData);
      if (mounted) {
        setState(() {
          _sendingReply = false;
          _replyCtrl.clear();
          _replyFiles = [];
        });
        _loadDetail(_selectedComplaint['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'replySent')),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _sendingReply = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t(context, 'errorPrefix')}${ApiService.failureFrom(error).message}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteComplaint(int id) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: t(context, 'deleteComplaint'),
      message: t(context, 'deleteComplaintConfirm'),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/complaints/$id');
      if (mounted) {
        _loadComplaints();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'complaintDeleted')),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t(context, 'errorPrefix')}${ApiService.failureFrom(error).message}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp3', 'wav', 'ogg', 'mp4', 'mov', 'avi'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files.where((f) => f.path != null).map((f) => File(f.path!)));
      });
    }
  }

  Future<void> _pickReplyFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp3', 'wav', 'ogg', 'mp4', 'mov', 'avi'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _replyFiles.addAll(result.files.where((f) => f.path != null).map((f) => File(f.path!)));
      });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return t(context, 'statusPending');
      case 'in_progress': return t(context, 'statusInProgress');
      case 'resolved': return t(context, 'statusResolved');
      case 'rejected': return t(context, 'statusRejected');
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.honey;
      case 'in_progress': return AppTheme.primary;
      case 'resolved': return AppTheme.mint;
      case 'rejected': return AppTheme.danger;
      default: return AppTheme.muted;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return t(context, 'roleAdmin');
      case 'teacher': return t(context, 'teacher');
      case 'student': return t(context, 'student');
      case 'parent': return t(context, 'parent');
      default: return role;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'normal': return t(context, 'priorityNormal');
      case 'high': return t(context, 'priorityHigh');
      case 'urgent': return t(context, 'priorityUrgent');
      default: return priority;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return AppTheme.danger;
      case 'high': return AppTheme.honey;
      default: return AppTheme.muted;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'in_progress': return Icons.sync;
      case 'resolved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedComplaint != null) {
      return _buildDetailView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        if (_showForm) ...[
          const SizedBox(height: 12),
          _buildForm(),
        ],
        const SizedBox(height: 12),
        if (_loading)
          const LoadingShimmer()
        else if (_error != null)
          Card(child: ListTile(leading: const Icon(Icons.error, color: Colors.red), title: Text(_error!)))
        else if (_complaints.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(t(context, 'noComplaints')),
              ),
            ),
          )
        else
          for (final c in _complaints) ...[
            _buildComplaintCard(c),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            t(context, 'complaintsTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (_selectedComplaint == null)
          FilledButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.close : Icons.add),
            label: Text(_showForm
                ? t(context, 'cancel')
                : t(context, 'newComplaint')),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(context, 'newComplaint'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: t(context, 'title'),
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t(context, 'description'),
                prefixIcon: const Icon(Icons.description),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: InputDecoration(
                labelText: t(context, 'priority'),
                prefixIcon: const Icon(Icons.flag),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'normal', child: Text(t(context, 'priorityNormal'))),
                DropdownMenuItem(value: 'high', child: Text(t(context, 'priorityHigh'))),
                DropdownMenuItem(value: 'urgent', child: Text(t(context, 'priorityUrgent'))),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'normal'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: Text(t(context, 'attachFiles')),
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('${_selectedFiles.length} ${t(context, 'files')}'),
                ],
              ],
            ),
            if (_selectedFiles.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _selectedFiles.asMap().entries.map((e) => Chip(
                  label: Text(e.value.path.split('\\').last, style: const TextStyle(fontSize: 11)),
                  onDeleted: () => setState(() => _selectedFiles.removeAt(e.key)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                )).toList(),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _submitComplaint,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_saving
                  ? t(context, 'sending')
                  : t(context, 'submit')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(dynamic c) {
    final status = c['status'] ?? 'pending';
    final priority = c['priority'] ?? 'normal';
    final title = c['title'] ?? '';
    final desc = c['description'];
    final date = _formatDate(c['created_at']);
    final repliesCount = c['replies_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _loadDetail(c['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ],
              ),
              if (desc != null && desc.toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc.toString().length > 100 ? '${desc.toString().substring(0, 100)}...' : desc.toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor(priority).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _priorityLabel(priority),
                      style: TextStyle(fontSize: 11, color: _priorityColor(priority), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  if (repliesCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.reply, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('$repliesCount', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  const SizedBox(width: 8),
                  Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final c = _selectedComplaint;
    if (c == null) return const SizedBox();
    if (_detailLoading) return const LoadingShimmer();

    final status = c['status'] ?? 'pending';
    final replies = c['replies'] ?? [];
    final attachments = c['attachments'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _selectedComplaint = null),
              icon: const Icon(Icons.arrow_back),
              label: Text(t(context, 'back')),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Complaint detail
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c['title'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteComplaint(c['id']),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t(context, 'by')} ${c['complainant_name'] ?? t(context, 'unknown')}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(c['created_at']),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
                if (c['description'] != null && c['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(c['description'], style: const TextStyle(height: 1.4)),
                  ),
                ],
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(t(context, 'attachments'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...attachments.map<Widget>((att) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {}, // open URL externally
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              att['original_filename'] ?? '',
                              style: const TextStyle(color: Colors.blue, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Replies
        Text(
          '${t(context, 'replies')} (${replies.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (replies.isEmpty)
          Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(t(context, 'noReplies'),
                  style: TextStyle(color: Colors.grey[500])),
            ),
          ))
        else
          ...replies.map<Widget>((r) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        r['user_name'] ?? t(context, 'unknown'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _roleLabel('${r['user_role'] ?? ''}'),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(r['created_at']),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r['message'] ?? '', style: const TextStyle(height: 1.3)),
                  if ((r['attachments'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    ...(r['attachments'] as List).map<Widget>((att) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            att['original_filename'] ?? '',
                            style: const TextStyle(color: Colors.blue, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          )),

        // Reply form (only if not resolved/rejected)
        if (status != 'resolved' && status != 'rejected') ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t(context, 'addReply'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t(context, 'replyHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickReplyFiles,
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(t(context, 'attachFiles')),
                  ),
                  if (_replyFiles.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: _replyFiles.asMap().entries.map((e) => Chip(
                        label: Text(e.value.path.split('\\').last, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => _replyFiles.removeAt(e.key)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      )).toList(),
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _sendingReply ? null : _sendReply,
                    icon: _sendingReply
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_sendingReply
                        ? t(context, 'sending')
                        : t(context, 'send')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
