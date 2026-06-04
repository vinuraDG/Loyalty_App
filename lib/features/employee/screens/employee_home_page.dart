// lib/features/employee/screens/employee_home_page.dart
//
// Refactored to use the new standalone QrScannerScreen and
// CustomerIdentifiedScreen instead of in-line bottom sheets.
// The fuel entry sheet is now in fuel_entry_sheet.dart.
// All scan + redeem logic is delegated to child screens.

import 'package:flutter/material.dart';
import 'package:loyalty_app/features/employee/screens/employee_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';
import '../data/emp_home_mock_service.dart';
import 'qr_scanner_screen.dart';
import 'customer_identified_screen.dart';

class EmployeeHomePage extends StatefulWidget {
  final UserModel employee;
  const EmployeeHomePage({super.key, required this.employee});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  // ── Swap to EmpHomeApiService.instance when backend is ready ──────────────
  final IEmpHomeService _svc = EmpHomeMockService.instance;

  List<ScanEntry> _todayScans = [];
  List<int> _weeklyCommission = List.filled(7, 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scans = await _svc.getTodayScans(widget.employee.id);
    final commission = await _svc.getWeeklyCommission(widget.employee.id);
    if (!mounted) return;
    setState(() {
      _todayScans = scans.toList();
      _weeklyCommission = commission;
      _loading = false;
    });
  }

  Future<void> _refreshScans() async {
    final scans = await _svc.getTodayScans(widget.employee.id);
    if (!mounted) return;
    setState(() => _todayScans = scans.toList());
  }

  double get _weeklyTotal =>
      _weeklyCommission.fold(0.0, (s, v) => s + v) / 100.0;

  double get _monthlyCommission => _weeklyTotal * 4.3;

  // ── QR scan entry point ───────────────────────────────────────────────────

  Future<void> _startScanFlow(BuildContext context) async {
    // 1. Navigate to the scanner screen — it returns a ScannedMember.
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

    // 2. Navigate to the customer screen for Earn / Redeem.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerIdentifiedScreen(
          member: member,
          employeeId: widget.employee.id,
          svc: _svc,
        ),
      ),
    );

    // 3. Refresh the today-scans list regardless of what happened.
    await _refreshScans();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text('Staff',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Commission card ──────────────────────────────────────
              _CommissionCard(
                monthlyCommission: _monthlyCommission,
                weeklyTotal: _weeklyTotal,
                weeklyCommission: _weeklyCommission,
                scanCount: _todayScans.length,
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────────────────
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
                  onTap: () {
                    final dashboard = context
                        .findAncestorStateOfType<
                            EmployeeDashboardScreenState>();
                    dashboard?.switchToCommission();
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // ── Today's scans ────────────────────────────────────────
              const Text("Today's Scans", style: AppTextStyles.h4),
              const SizedBox(height: 14),
              if (_todayScans.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No scans yet today.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                )
              else
                ..._todayScans.map((s) => _TodayScanTile(scan: s)),

              const SizedBox(height: 8),
            ],
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
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.payments_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.55)),
                  const SizedBox(width: 5),
                  Text('commission',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400)),
                ]),
                const SizedBox(height: 6),
                Text(
                  'LKR ${monthlyCommission.toStringAsFixed(0)}',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  width: 80,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.calendar_view_week_rounded,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'This week  LKR ${weeklyTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  '$scanCount transactions · 2% rate',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 7 days',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.3),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 80,
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
                fontWeight:
                    isToday ? FontWeight.w700 : FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scan.memberName, style: AppTextStyles.labelMedium),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.payments_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'LKR ${scan.saleAmount.toStringAsFixed(0)}  •  ${scan.time}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('+${scan.points} pts',
              style: AppTextStyles.caption.copyWith(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
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
                style: AppTextStyles.caption.copyWith(
                    fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}