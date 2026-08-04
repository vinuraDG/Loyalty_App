// lib/features/employee/screens/employee_home_page.dart

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/home/data/emp_home_api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_real_service.dart';
import '../../commission/data/emp_commission_api_service.dart';
import 'qr_scanner_screen.dart';
import 'customer_identified_screen.dart';
import '../../commission/screens/employee_commission_page.dart';
import 'employee_dashboard_screen.dart';

class EmployeeHomePage extends StatefulWidget {
  final UserModel employee;
  const EmployeeHomePage({super.key, required this.employee});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final IEmpHomeService _svc = empHomeService;
  final _commissionSvc = empCommissionService;

  List<ScanEntry> _todayScans = [];
  List<int> _weeklyCommission = List.filled(7, 0);
  double _monthlyCommission = 0.0;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scans = await _svc.getTodayScans(widget.employee.id);
      final commission = await _svc.getWeeklyCommission(widget.employee.id);
      List<SaleEntry> fuelSales = [];
      try {
        fuelSales = await _commissionSvc.getSalesForMonth(
            widget.employee.id, _currentMonthKey);
      } catch (_) {}
      final monthlyCommission =
          fuelSales.fold<double>(0.0, (a, s) => a + s.commission);
      if (!mounted) return;
      setState(() {
        _todayScans = scans.reversed.toList();
        _weeklyCommission = commission;
        _monthlyCommission = monthlyCommission;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Refreshes all home-page data in parallel. Each fetch is independent —
  // a failure in one (e.g. commission) does not block the others from updating.
  Future<void> _silentRefresh() async {
    List<ScanEntry>? newScans;
    List<int>?       newWeekly;
    double?          newMonthly;

    await Future.wait([
      _svc.getTodayScans(widget.employee.id)
          .then((s) => newScans = s.reversed.toList())
          .catchError((_) {}),
      _svc.getWeeklyCommission(widget.employee.id)
          .then((w) => newWeekly = w)
          .catchError((_) {}),
      _commissionSvc.getSalesForMonth(widget.employee.id, _currentMonthKey)
          .then((s) => newMonthly = s.fold<double>(0.0, (a, e) => a + e.commission))
          .catchError((_) {}),
    ]);

    if (!mounted) return;
    setState(() {
      if (newScans   != null) _todayScans        = newScans!;
      if (newWeekly  != null) _weeklyCommission  = newWeekly!;
      if (newMonthly != null) _monthlyCommission = newMonthly!;
    });
  }

  double get _weeklyTotal =>
      _weeklyCommission.fold(0.0, (s, v) => s + v.toDouble());

  Future<void> _startScanFlow(BuildContext context) async {
    final member = await Navigator.push<ScannedMember>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          employeeId: widget.employee.id,
          svc: _svc,
        ),
      ),
    );

    if (member == null || !context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerIdentifiedScreen(
          member: member,
          employeeId: widget.employee.id,
          svc: _svc,
          employee: widget.employee,
        ),
      ),
    );

    await _silentRefresh();
  }

  // Both the commission card and the "My Commission" quick action open the
  // same commission page (has month picker + full history).
  void _goToCommission(BuildContext context) {
    final dashboard =
        context.findAncestorStateOfType<EmployeeDashboardScreenState>();
    if (dashboard != null) {
      dashboard.switchToCommission();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeCommissionPage(employee: widget.employee),
        ),
      );
    }
  }

  void _goToCommissionTab(BuildContext context) => _goToCommission(context);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  onPressed: _load,
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
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bgCard,
          onRefresh: _silentRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(children: [
                InitialsAvatar(initials: widget.employee.initials, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,', style: AppTextStyles.caption),
                      Text(widget.employee.name, style: AppTextStyles.h4),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Commission card ────────────────────────────────────────
              // instead of Navigator.push (which loses the bottom nav shell).
              GestureDetector(
                onTap: () => _goToCommission(context),
                child: _CommissionCard(
                  monthlyCommission: _monthlyCommission,
                  weeklyTotal: _weeklyTotal,
                  weeklyCommission: _weeklyCommission,
                  scanCount: _todayScans.length,
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ─────────────────────────────────────────
              const Text('Quick Actions', style: AppTextStyles.h4),
              const SizedBox(height: 14),
              Row(children: [
                _EmpQuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  color: AppColors.primaryLight,
                  onTap: () => _startScanFlow(context),
                ),
                const SizedBox(width: 10),
                _EmpQuickAction(
                  icon: Icons.payments_outlined,
                  label: 'My Commission',
                  color: AppColors.primary,
                  onTap: () => _goToCommissionTab(context),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Today's scans ─────────────────────────────────────────
              const Text('Today Scans', style: AppTextStyles.h4),
              const SizedBox(height: 14),
              if (_todayScans.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No scans yet today.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ..._todayScans.map((s) => _TodayScanTile(scan: s)),

              const SizedBox(height: 8),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Commission card ───────────────────────────────────────────────────────────

class _CommissionCard extends StatelessWidget {
  final double monthlyCommission;
  final double weeklyTotal;
  final List<int> weeklyCommission;
  final int scanCount;

  const _CommissionCard({
    required this.monthlyCommission,
    required this.weeklyTotal,
    required this.weeklyCommission,
    required this.scanCount,
  });

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: label + amount + tap hint ───────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.payments_outlined,
                      size: 13, color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(width: 5),
                  Text(
                    'Commission',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w400),
                  ),
                ]),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LKR ${formatAmount(monthlyCommission)}',
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    Icon(Icons.open_in_new_rounded,
                        size: 10, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view commission',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Right: "This week" label + chart ──────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    Icon(Icons.calendar_view_week_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.55)),
                    const SizedBox(width: 4),
                    Text(
                      'This week  ',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    Text(
                      'LKR ${formatAmount(weeklyTotal)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 72,
                  child: _WeeklyCommissionChart(data: weeklyCommission),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly commission bar chart ───────────────────────────────────────────────

class _WeeklyCommissionChart extends StatelessWidget {
  final List<int> data;
  const _WeeklyCommissionChart({required this.data});
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final todayIdx = DateTime.now().weekday - 1;

    return Column(children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final ratio =
                maxVal > 0 ? (data[i] / maxVal).clamp(0.08, 1.0) : 0.08;
            final isToday = i == todayIdx;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: List.generate(7, (i) {
          final isToday = i == DateTime.now().weekday - 1;
          return Expanded(
            child: Text(
              _dayLabels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isToday
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.4),
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

// ── Today scan tile ───────────────────────────────────────────────────────────

class _TodayScanTile extends StatelessWidget {
  final ScanEntry scan;
  const _TodayScanTile({required this.scan});

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
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
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

            // Commission amount
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '+LKR ${formatAmount(scan.commission)}',
                style: AppTextStyles.display
                    .copyWith(fontSize: 34, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 4),

            // Badge
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

            // Detail rows
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                if (scan.documentNumber.isNotEmpty) ...[
                  _ScanDetailRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'Document No',
                      value: scan.documentNumber),
                  _ScanDivider(),
                ],
                if (scan.memberName.isNotEmpty) ...[
                  _ScanDetailRow(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: scan.memberName),
                  _ScanDivider(),
                ],
                _ScanDetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Sale amount',
                    value: 'LKR ${formatAmount(scan.saleAmount)}'),
                _ScanDivider(),
                _ScanDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: scan.date),
                _ScanDivider(),
                _ScanDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: scan.time),
                _ScanDivider(),
                _ScanDetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Commission',
                    value: 'LKR ${formatAmount(scan.commission)}',
                    valueColor: Colors.greenAccent),
              ]),
            ),
            const SizedBox(height: 16),

            // Close button
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
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
                Text(
                  scan.memberName.isNotEmpty ? scan.memberName : 'Customer',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${scan.date}  ${scan.time}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  'Sale: LKR ${formatAmount(scan.saleAmount)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
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
                '+LKR ${formatAmount(scan.commission)}',
                style: AppTextStyles.caption.copyWith(
                    color: Colors.greenAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Scan detail popup helpers ─────────────────────────────────────────────────

class _ScanDetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _ScanDetailRow({
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

class _ScanDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: AppColors.border,
      );
}

// ── Employee Quick Action card ────────────────────────────────────────────────

class _EmpQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EmpQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}