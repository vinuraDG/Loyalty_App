// lib/features/employee/screens/employee_commission_page.dart

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/data/emp_commission_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../data/emp_commission_mock_service.dart';

class EmployeeCommissionPage extends StatefulWidget {
  final UserModel employee;
  const EmployeeCommissionPage({super.key, required this.employee});

  @override
  State<EmployeeCommissionPage> createState() =>
      _EmployeeCommissionPageState();
}

class _EmployeeCommissionPageState extends State<EmployeeCommissionPage> {
  final _svc = EmpCommissionMockService.instance;

  List<String> _months = [];
  String? _selectedMonth;
  int _monthIdx = 0;
  List<SaleEntry> _sales = [];
  MonthlySummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    final months = await _svc.getAvailableMonths(widget.employee.id);
    if (!mounted) return;
    setState(() {
      _months = months;
      _selectedMonth = months.isNotEmpty ? months.first : null;
      _monthIdx = 0;
    });
    if (_selectedMonth != null) await _loadMonth(_selectedMonth!);
  }

  Future<void> _loadMonth(String month) async {
    setState(() => _loading = true);
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
                  const Text('Per-sale earnings breakdown',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),

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
                                  _selectedMonth!,
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
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _sales.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _SaleTile(sale: _sales[i]),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(summary.month,
            style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          'LKR ${summary.totalCommission.toStringAsFixed(2)}',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Total sales: LKR ${summary.totalSales.toStringAsFixed(0)}',
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(
              label: 'Transactions',
              value: '${summary.transactionCount}'),
          const SizedBox(width: 28),
          _MiniStat(
              label: 'Customers',
              value: '${summary.uniqueCustomers}'),
        ]),
      ]),
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
    return Container(
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
                    '${sale.date}  ${sale.time}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text('Sale: LKR ${sale.saleAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+LKR ${sale.commission.toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
  
}
