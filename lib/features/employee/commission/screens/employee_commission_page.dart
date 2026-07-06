// lib/features/employee/screens/employee_commission_page.dart

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/commission/data/emp_commission_api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/user_model.dart';

// ── Helper: full date with year, derived from SaleEntry.month ────────────────
extension _SaleDate on SaleEntry {
  String get fullDate {
    final year = month.split(' ').last;
    return '$date $year';
  }
}

class EmployeeCommissionPage extends StatefulWidget {
  final UserModel employee;
  const EmployeeCommissionPage({super.key, required this.employee});

  @override
  State<EmployeeCommissionPage> createState() =>
      _EmployeeCommissionPageState();
}

class _EmployeeCommissionPageState extends State<EmployeeCommissionPage> {
  final _svc = empCommissionService;

  List<String> _months = [];
  String? _selectedMonth;
  int _monthIdx = 0;
  List<SaleEntry> _sales = [];
  MonthlySummary? _summary;
  bool _loading = true;
  String? _error;

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${_shortMonths[now.month - 1]} ${now.year}';
  }

  /// Shows "This Month" for the currently active month, real name otherwise.
  String _monthLabel(String month) =>
      month == _currentMonthKey ? 'This Month' : month;

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    setState(() { _loading = true; _error = null; });
    try {
      final months = await _svc.getAvailableMonths(widget.employee.id);
      if (!mounted) return;
      setState(() {
        _months = months;
        _selectedMonth = months.isNotEmpty ? months.first : null;
        _monthIdx = 0;
      });
      if (_selectedMonth != null) await _loadMonth(_selectedMonth!);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMonth(String month) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _svc.getSalesForMonth(widget.employee.id, month),
        _svc.getMonthlySummary(widget.employee.id, month),
      ]);
      if (!mounted) return;
      setState(() {
        _sales   = results[0] as List<SaleEntry>;
        _summary = results[1] as MonthlySummary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _pickMonth(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Month', style: AppTextStyles.h4),
          ),
          const SizedBox(height: 8),
          ...List.generate(_months.length, (i) {
            final m   = _months[i];
            final sel = _monthIdx == i;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: sel ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                m,
                style: AppTextStyles.labelMedium.copyWith(
                  color: sel ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: sel
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                setState(() {
                  _monthIdx      = i;
                  _selectedMonth = m;
                });
                Navigator.pop(context);
                _loadMonth(m);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadMonths,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Commission', style: AppTextStyles.h3),
            ),

            // ── Subtitle + summary card + month picker ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 

                  if (_summary != null) _SummaryCard(summary: _summary!),
                  if (_summary != null) const SizedBox(height: 20),

                  if (!_loading && _selectedMonth != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sales in $_selectedMonth',
                          style: AppTextStyles.h4,
                        ),
                        GestureDetector(
                          onTap: () => _pickMonth(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 13, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _monthLabel(_selectedMonth!),
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.primary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Sales list ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _sales.isEmpty
                      ? Center(
                          child: Text(
                            'No sales recorded for $_selectedMonth',
                            style: AppTextStyles.bodySmall,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.bgCard,
                          onRefresh: () => _selectedMonth != null
                              ? _loadMonth(_selectedMonth!)
                              : _loadMonths(),
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _sales.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _SaleTile(sale: _sales[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  const _SummaryCard({required this.summary});

@override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(summary.month,
              style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'LKR ${formatAmount(summary.totalCommission)}',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
       
          Row(children: [
            _MiniStat(
                label: 'Transactions',
                value: '${summary.transactionCount}'),
            const SizedBox(width: 28),
            _MiniStat(
                label: 'Customers',
                value: '${summary.uniqueCustomers}'),
          ]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: AppTextStyles.h4.copyWith(color: Colors.white)),
      Text(label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60)),
    ]);
  }
}

// ── Sale tile ─────────────────────────────────────────────────────────────────

class _SaleTile extends StatelessWidget {
  final SaleEntry sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station_rounded,
                color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.customerName, style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.water_drop_outlined,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text('${sale.litres.toStringAsFixed(1)} L',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${sale.fullDate}  ${sale.time}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text('Sale: LKR ${formatAmount(sale.saleAmount)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+LKR ${formatAmount(sale.commission)}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Handle ──────────────────────────────────────────────────
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Icon ────────────────────────────────────────────────────
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: AppColors.primaryLight, size: 30),
            ),
            const SizedBox(height: 12),

            // ── Commission amount ────────────────────────────────────────
            Text(
              '+LKR ${formatAmount(sale.commission)}',
              style: AppTextStyles.display
                  .copyWith(fontSize: 34, color: Colors.greenAccent),
            ),
            const SizedBox(height: 4),

            // ── Badge ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Commission Earned',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Detail rows ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Customer',
                    value: sale.customerName),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Sale amount',
                    value: 'LKR ${formatAmount(sale.saleAmount)}'),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Litres',
                    value: '${sale.litres.toStringAsFixed(1)} L'),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: sale.fullDate),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: sale.time),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Commission',
                    value: 'LKR ${formatAmount(sale.commission)}',
                    valueColor: Colors.greenAccent),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Close button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Close',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TxDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.border,
      );
}