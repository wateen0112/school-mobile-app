import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/module_localization.dart';
import '../../core/network/api_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';

class ParentFinanceContent extends StatefulWidget {
  const ParentFinanceContent({super.key});

  @override
  State<ParentFinanceContent> createState() => _ParentFinanceContentState();
}

class _ParentFinanceContentState extends State<ParentFinanceContent> {
  late final dynamic _api;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const {};
  List<dynamic> _children = [];

  @override
  void initState() {
    super.initState();
    _api = context.read<SessionController>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await _api.get('/parent/finance');
      if (!mounted) return;
      setState(() {
        final data = body['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(body['data'])
            : <String, dynamic>{};
        _summary = data['summary'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['summary'])
            : const {};
        final children = data['children'];
        _children = children is List ? children : [];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.failureFrom(error).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.coral),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      appIsArabic(context) ? 'إعادة المحاولة' : 'Retry',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_children.isEmpty) {
      return const SizedBox(height: 260);
    }

    final isAr = appIsArabic(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverallSummary(summary: _summary, isAr: isAr),
        const SizedBox(height: 12),
        for (final child in _children) ...[
          _ChildFinanceCard(child: child, isAr: isAr),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OverallSummary extends StatelessWidget {
  const _OverallSummary({required this.summary, required this.isAr});

  final Map<String, dynamic> summary;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final invoiced = _num(summary['total_invoiced']);
    final paid = _num(summary['total_paid']);
    final remaining = _num(summary['total_remaining']);
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'الملخص المالي' : 'Financial summary',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'إجمالي الرسوم' : 'Total due',
                    value: _money(invoiced),
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'المدفوع' : 'Paid',
                    value: _money(paid),
                    color: const Color(0xFF1B8A4C),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'المتبقي' : 'Remaining',
                    value: _money(remaining),
                    color: remaining > 0
                        ? AppTheme.coral
                        : const Color(0xFF1B8A4C),
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

class _ChildFinanceCard extends StatelessWidget {
  const _ChildFinanceCard({required this.child, required this.isAr});

  final dynamic child;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final finance = child['finance'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(child['finance'])
        : <String, dynamic>{};
    final invoices = (child['invoices'] is List)
        ? (child['invoices'] as List).cast<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    final receipts = (child['receipts'] is List)
        ? (child['receipts'] as List).cast<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    final childRemaining = _num(finance['remaining']);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${child['name'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                              child['grade_name'],
                              child['classroom_name'],
                              child['section_name'],
                            ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' • '),
                        style: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: childRemaining > 0
                      ? (isAr ? 'غير مسدد' : 'Unpaid')
                      : (isAr ? 'مسدد' : 'Settled'),
                  color: childRemaining > 0
                      ? AppTheme.coral
                      : const Color(0xFF1B8A4C),
                  remaining: childRemaining,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'إجمالي الرسوم' : 'Invoiced',
                    value: _money(_num(finance['total_invoiced'])),
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'المدفوع' : 'Paid',
                    value: _money(_num(finance['total_paid'])),
                    color: const Color(0xFF1B8A4C),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: isAr ? 'المتبقي' : 'Remaining',
                    value: _money(_num(finance['remaining'])),
                    color: _num(finance['remaining']) > 0
                        ? AppTheme.coral
                        : const Color(0xFF1B8A4C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.receipt_long_rounded,
              title: isAr ? 'الرسوم والفواتير' : 'Fees & invoices',
              count: invoices.length,
            ),
            const SizedBox(height: 8),
            if (invoices.isEmpty)
              _EmptyNote(
                text: isAr
                    ? 'لا توجد فواتير لهذا الابن'
                    : 'No invoices for this child',
              )
            else
              for (final invoice in invoices)
                _InvoiceTile(invoice: invoice, isAr: isAr),
            const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.payments_rounded,
              title: isAr ? 'السندات والمدفوعات' : 'Receipts & payments',
              count: receipts.length,
            ),
            const SizedBox(height: 8),
            if (receipts.isEmpty)
              _EmptyNote(
                text: isAr
                    ? 'لا توجد مدفوعات مسجلة لهذا الابن'
                    : 'No payments recorded for this child',
              )
            else
              for (final receipt in receipts)
                _ReceiptTile(receipt: receipt, isAr: isAr),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.isAr});

  final Map<String, dynamic> invoice;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] ?? 'unpaid';
    final (Color statusColor, String statusLabel) = switch (status) {
      'paid' => (const Color(0xFF1B8A4C), isAr ? 'مدفوعة' : 'Paid'),
      'partial' => (
        const Color(0xFFC77700),
        isAr ? 'مدفوعة جزئياً' : 'Partial',
      ),
      _ => (AppTheme.coral, isAr ? 'غير مدفوعة' : 'Unpaid'),
    };
    final feeTitle = isAr
        ? (invoice['fee_title_ar'] ?? '')
        : (invoice['fee_title_en'] ?? '');
    final amount = _num(invoice['amount']);
    final paid = _num(invoice['paid']);
    final remaining = _num(invoice['remaining']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feeTitle.toString().isEmpty
                      ? (isAr ? 'رسم دراسي' : 'Fee')
                      : feeTitle.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if ((invoice['fee_type'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              invoice['fee_type'].toString(),
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: AppTheme.ink.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              Text(
                invoice['invoice_date']?.toString() ?? '-',
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _money(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isAr ? 'المدفوع' : 'Paid'}: ${_money(paid)}  •  ${isAr ? 'المتبقي' : 'Remaining'}: ${_money(remaining)}',
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if ((invoice['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              invoice['description'].toString(),
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.55),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.isAr});

  final Map<String, dynamic> receipt;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF1B8A4C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((receipt['description'] ?? '').toString().isNotEmpty)
                  Text(
                    receipt['description'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  '${isAr ? 'التاريخ' : 'Date'}: ${receipt['date']?.toString() ?? '-'}',
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(_num(receipt['amount'])),
            style: const TextStyle(
              color: Color(0xFF1B8A4C),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    this.remaining = 0,
  });

  final String label;
  final Color color;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final showLabel = remaining > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        showLabel
            ? '$label · ${_money(remaining)}'
            : (remaining == 0 ? label : ''),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.ink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.ink.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }
}

double _num(dynamic value) {
  if (value == null) return 0;
  return double.tryParse(value.toString()) ?? 0;
}

String _money(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}
