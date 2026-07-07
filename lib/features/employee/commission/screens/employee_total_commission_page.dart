// lib/features/employee/screens/employee_total_commission_page.dart

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/commission/data/emp_commission_api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/user_model.dart';

class EmployeeTotalCommissionPage extends StatefulWidget {
  final UserModel employee;
  const EmployeeTotalCommissionPage({super.key, required this.employee});

  @override
  State<EmployeeTotalCommissionPage> createState() =>
      _EmployeeTotalCommissionPageState();
}

class _EmployeeTotalCommissionPageState
    extends State<EmployeeTotalCommissionPage> {
  final _svc = empCommissionService;

  List<SaleEntry> _fuelSales = [];
  bool _loading = true;

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${_shortMonths[now.month - 1]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentMonth();
  }

  Future<void> _loadCurrentMonth() async {
    final sales =
        await _svc.getSalesForMonth(widget.employee.id, _currentMonthKey);
    if (!mounted) return;
    setState(() {
      _fuelSales = sales.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Commission History', style: AppTextStyles.h3),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final totalCommission =
        _fuelSales.fold<double>(0.0, (a, t) => a + t.commission);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      onRefresh: _loadCurrentMonth,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Monthly commission card ───────────────────────────────────────
        Container(
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Commission',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.fuelColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.fuelColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_gas_station_rounded,
                          size: 11, color: AppColors.fuelColor),
                      const SizedBox(width: 4),
                      Text('Fuel',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.fuelColor,
                            fontWeight: FontWeight.w600,
                          )),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'LKR ${formatAmount(totalCommission)}',
                  style: AppTextStyles.display.copyWith(fontSize: 34),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: Colors.white.withValues(alpha: 0.45)),
                const SizedBox(width: 6),
                Text(
                  'Earned from Fuel Sales · This Month',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Transaction history header ─────────────────────────────────────
        const Text('Transaction History', style: AppTextStyles.h4),
        const SizedBox(height: 14),

        // ── Transaction list ───────────────────────────────────────────────
        if (_fuelSales.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.local_gas_station_outlined,
                    color: AppColors.textSecondary, size: 40),
                SizedBox(height: 8),
                Text(
                  'No fuel sales recorded.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          )
        else
          ..._fuelSales.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FuelSaleTile(sale: s),
              )),

        const SizedBox(height: 20),
      ]),
      ),
    );
  }
}

// ── Extension: full date with year ───────────────────────────────────────────

extension _SaleDate on SaleEntry {
  String get fullDate {
    final year = month.split(' ').last;
    return '$date $year';
  }
}

// ── Fuel sale tile ────────────────────────────────────────────────────────────

class _FuelSaleTile extends StatelessWidget {
  final SaleEntry sale;
  const _FuelSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.fuelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: AppColors.fuelColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.customerName.isNotEmpty ? sale.customerName : 'Customer',
                    style: AppTextStyles.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(sale.fullDate,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(sale.time,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '+LKR ${formatAmount(sale.commission)}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 2),
              Text(
                'LKR ${formatAmount(sale.saleAmount)} sale',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ]),
          ]),
        ),
      );

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
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.fuelColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: AppColors.fuelColor, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              '+LKR ${formatAmount(sale.commission)}',
              style: AppTextStyles.display
                  .copyWith(fontSize: 34, color: Colors.greenAccent),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fuelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Commission Earned',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.fuelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                if (sale.customerName.isNotEmpty) ...[
                  _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: sale.customerName),
                  _TxDivider(),
                ],
                _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Sale amount',
                    value: 'LKR ${formatAmount(sale.saleAmount)}'),
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
                  child: const Text(
                    'Close',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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