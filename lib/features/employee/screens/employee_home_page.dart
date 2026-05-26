import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── Mock scanned customer ─────────────────────────────────────────────────────

class _ScannedMember {
  final String name;
  final String memberId;
  final String tier;
  final int currentPoints;
  const _ScannedMember({
    required this.name,
    required this.memberId,
    required this.tier,
    required this.currentPoints,
  });
}

const _mockScannedMember = _ScannedMember(
  name: 'Amal Perera',
  memberId: 'AP2024X1',
  tier: 'Gold',
  currentPoints: 3420,
);

// ── Mock data ─────────────────────────────────────────────────────────────────

// Weekly commission data (Mon–Sun) — used for the bar chart
const _mockWeeklyCommission = [1240, 3800, 2650, 4200, 5100, 3200, 800];

// Monthly commission total in LKR (replace with real value from your service)
const double _mockMonthlyCommission = 1240.00; // LKR 87,450

// ── Page ──────────────────────────────────────────────────────────────────────

class EmployeeHomePage extends StatefulWidget {
  final UserModel employee;
  const EmployeeHomePage({super.key, required this.employee});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final List<_ScanEntry> _recentScans = [
    const _ScanEntry(memberName: 'Nimal Silva',       saleAmount: 3565,  points: 180, time: '10:15 AM'),
    const _ScanEntry(memberName: 'Kamani Fernando',   saleAmount: 10350, points: 320, time: '9:58 AM'),
    const _ScanEntry(memberName: 'Ruwan Jayawardena', saleAmount: 4600,  points: 150, time: '9:40 AM'),
    const _ScanEntry(memberName: 'Dilini Ratnayake',  saleAmount: 13800, points: 400, time: '9:22 AM'),
  ];

  double get _weeklyCommissionTotal =>
      _mockWeeklyCommission.fold(0.0, (s, v) => s + v) / 100.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ──────────────────────────────────────────────
            Row(children: [
              InitialsAvatar(initials: widget.employee.initials, size: 42),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,', style: AppTextStyles.caption),
                  Text(widget.employee.name, style: AppTextStyles.h4),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text('Staff',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Commission card ──────────────────────────────────────
            Container(
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

                  // ── Left: monthly commission total ─────────────────
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Label row — Flexible is correct here (inside Row)
                        Row(children: [
                          Icon(Icons.payments_outlined,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.55)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "This month's commission",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),

                        // Monthly amount — plain Text inside Column, no Flexible needed
                        Text(
                          'LKR ${_mockMonthlyCommission.toStringAsFixed(0)}',
                          style: AppTextStyles.h3.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),

                        // Subtle divider
                        Container(
                          height: 1,
                          width: 80,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 6),

                        // Weekly sub-total row — Flexible is correct here (inside Row)
                        Row(children: [
                          Icon(Icons.calendar_view_week_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'This week  LKR ${_weeklyCommissionTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 3),

                        // Transaction count — plain Text inside Column
                        Text(
                          '${_recentScans.length} transactions · 2% rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Right: weekly bar chart ────────────────────────
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
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(
                          height: 80,
                          child: _WeeklyCommissionChart(
                            data: _mockWeeklyCommission,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Scan Member button ───────────────────────────────────
            const Text('Quick Actions', style: AppTextStyles.h4),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _startScanFlow(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.primaryLight, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scan Member QR', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 2),
                      Text('Scan QR code to identify member and add fuel',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  )),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── Today's scan history ─────────────────────────────────
            const Text("Today's Scans", style: AppTextStyles.h4),
            const SizedBox(height: 14),
            if (_recentScans.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No scans yet today.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ),
              )
            else
              ..._recentScans.map((s) => _TodayScanTile(scan: s)),

            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Step 1: Scanning sheet ─────────────────────────────────────────────────
  void _startScanFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.primaryLight, size: 44),
          ),
          const SizedBox(height: 18),
          const Text('Scan Member QR', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          const Text(
            "Point the camera at the member's QR code to identify them.",
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Open Camera',
            icon: Icons.camera_alt_outlined,
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) _showCustomerSheet(context);
              });
            },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Step 2: Customer identified sheet ─────────────────────────────────────
  void _showCustomerSheet(BuildContext context) {
    const member = _mockScannedMember;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 30),
          ),
          const SizedBox(height: 12),
          const Text('Member Identified', style: AppTextStyles.h4),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              InitialsAvatar(
                initials: member.name.split(' ').map((w) => w[0]).take(2).join(),
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 3),
                  Text('ID: #${member.memberId}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  Text('${member.currentPoints} pts  •  ${member.tier}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryLight)),
                ],
              )),
              TierBadge(tier: member.tier),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textMuted)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: 'Add Fuel',
                icon: Icons.local_gas_station_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) _showFuelEntry(context, member);
                  });
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Step 3: Fuel amount entry sheet ───────────────────────────────────────
  void _showFuelEntry(BuildContext context, _ScannedMember member) {
    final amountCtrl = TextEditingController();
    const double pointsPerLkr = 0.1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final amount = double.tryParse(amountCtrl.text) ?? 0;
          final points = (amount * pointsPerLkr).toInt();

          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              const Row(children: [
                Icon(Icons.local_gas_station_rounded,
                    color: AppColors.primaryLight, size: 22),
                SizedBox(width: 10),
                Text('Add Fuel Details', style: AppTextStyles.h4),
              ]),
              const SizedBox(height: 6),
              Text('For ${member.name}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Sale Amount (LKR)',
                hint: 'e.g. 7015',
                controller: amountCtrl,
                prefixIconData: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: 16),

              if (amount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.stars_rounded,
                        color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Member will earn  +$points pts',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.greenAccent),
                    )),
                    Text('(LKR ${amount.toStringAsFixed(0)} × 0.1)',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.green.shade300)),
                  ]),
                ),

              const SizedBox(height: 20),

              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: 'Confirm & Award',
                    icon: Icons.check_rounded,
                    onPressed: amount > 0
                        ? () {
                            Navigator.pop(sheetCtx);
                            _onTransactionComplete(
                                context, member, amount, points);
                          }
                        : null,
                  ),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── Step 4: Complete + update state ───────────────────────────────────────
  void _onTransactionComplete(BuildContext context, _ScannedMember member,
      double amount, int points) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period.name.toUpperCase()}';

    setState(() {
      _recentScans.insert(
        0,
        _ScanEntry(
          memberName: member.name,
          saleAmount: amount,
          points: points,
          time: timeStr,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '+$points pts awarded to ${member.name}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          )),
        ]),
        duration: const Duration(seconds: 3),
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

    return Column(
      children: [
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
      ],
    );
  }
}

// ── Supporting models & widgets ───────────────────────────────────────────────

class _ScanEntry {
  final String memberName;
  final double saleAmount;
  final int points;
  final String time;
  const _ScanEntry({
    required this.memberName,
    required this.saleAmount,
    required this.points,
    required this.time,
  });
}

class _TodayScanTile extends StatelessWidget {
  final _ScanEntry scan;
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
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(scan.memberName, style: AppTextStyles.labelMedium),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.payments_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                'LKR ${scan.saleAmount.toStringAsFixed(0)}  •  ${scan.time}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ])),
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