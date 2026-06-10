// lib/features/employee/screens/employee_total_commission_page.dart

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/data/emp_commission_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../data/emp_commission_mock_service.dart';

class EmployeeTotalCommissionPage extends StatefulWidget {
  final UserModel employee;
  const EmployeeTotalCommissionPage({super.key, required this.employee});

  @override
  State<EmployeeTotalCommissionPage> createState() =>
      _EmployeeTotalCommissionPageState();
}

class _EmployeeTotalCommissionPageState
    extends State<EmployeeTotalCommissionPage> {
  final _svc = EmpCommissionMockService.instance;

  List<SaleEntry> _allFuelSales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Build last 6 month keys to fetch across all months
    final now = DateTime.now();
    const shortMonths = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final monthKeys = List.generate(6, (i) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) { m += 12; y -= 1; }
      return '${shortMonths[m - 1]} $y';
    });

    final results = await Future.wait(
      monthKeys.map((k) => _svc.getSalesForMonth(widget.employee.id, k)),
    );
    if (!mounted) return;
    setState(() {
      _allFuelSales = results
          .expand((l) => l)
          .where((s) => s.business == 'Fuel')
          .toList();
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
              const Text('Fuel Commission History', style: AppTextStyles.h3),
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
        _allFuelSales.fold<double>(0.0, (a, t) => a + t.commission);
    final totalSales =
        _allFuelSales.fold<double>(0.0, (a, t) => a + t.saleAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Total commission card (height 160) ────────────────────────────
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: fuel badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Commission',
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
                      Icon(Icons.local_gas_station_rounded,
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

              // Big commission number
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'LKR ${totalCommission.toStringAsFixed(2)}',
                  style: AppTextStyles.display.copyWith(fontSize: 34),
                ),
              ),

              // Stats row: sales + commission
              Row(children: [
                _CardStat(
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.success,
                  label: 'Total Sales',
                  value: 'LKR ${totalSales.toStringAsFixed(0)}',
                  valueColor: AppColors.success,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1, height: 32,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),
                _CardStat(
                  icon: Icons.receipt_long_rounded,
                  iconColor: Colors.white70,
                  label: 'Transactions',
                  value: '${_allFuelSales.length}',
                  valueColor: Colors.white,
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
        if (_allFuelSales.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.local_gas_station_outlined,
                    color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'No fuel sales recorded.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          )
        else
          ..._allFuelSales.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FuelSaleTile(sale: s),
              )),

        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Card stat ─────────────────────────────────────────────────────────────────

class _CardStat extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;
  final Color    valueColor;

  const _CardStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.45),
                  )),
            ],
          ),
        ],
      );
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
                  Text(sale.customerName,
                      style: AppTextStyles.labelMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${sale.date}  ·  ${sale.time}',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '+LKR ${sale.commission.toStringAsFixed(2)}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 2),
              Text(
                'LKR ${sale.saleAmount.toStringAsFixed(0)} sale',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ]),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textSecondary),
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
              '+LKR ${sale.commission.toStringAsFixed(2)}',
              style: AppTextStyles.display
                  .copyWith(fontSize: 34, color: AppColors.success),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fuelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Fuel Commission Earned',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.fuelColor,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                _DetailRow(icon: Icons.person_rounded,
                    label: 'Customer',    value: sale.customerName),
                _TxDivider(),
                _DetailRow(icon: Icons.payments_outlined,
                    label: 'Sale amount',
                    value: 'LKR ${sale.saleAmount.toStringAsFixed(0)}'),
                _TxDivider(),
                _DetailRow(icon: Icons.calendar_today_rounded,
                    label: 'Date',        value: sale.date),
                _TxDivider(),
                _DetailRow(icon: Icons.access_time_rounded,
                    label: 'Time',        value: sale.time),
                _TxDivider(),
                _DetailRow(
                    icon: Icons.percent_rounded,
                    label: 'Commission (2%)',
                    value: 'LKR ${sale.commission.toStringAsFixed(2)}',
                    valueColor: AppColors.success),
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

// ── Shared detail row + divider ───────────────────────────────────────────────

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
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
              )),
        ]),
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