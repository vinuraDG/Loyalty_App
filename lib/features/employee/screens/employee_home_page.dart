import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Simulated QR decode result
const _mockScannedMember = _ScannedMember(
  name: 'Amal Perera',
  memberId: 'AP2024X1',
  tier: 'Gold',
  currentPoints: 3420,
);

// ── Page ──────────────────────────────────────────────────────────────────────

class EmployeeHomePage extends StatefulWidget {
  final UserModel employee;
  const EmployeeHomePage({super.key, required this.employee});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  // Recent scans list — grows as employee completes transactions
  final List<_ScanEntry> _recentScans = [
    const _ScanEntry(memberName: 'Nimal Silva',       litres: 15.5, points: 180, time: '10:15 AM'),
    const _ScanEntry(memberName: 'Kamani Fernando',   litres: 45.0, points: 320, time: '9:58 AM'),
    const _ScanEntry(memberName: 'Ruwan Jayawardena', litres: 20.0, points: 150, time: '9:40 AM'),
    const _ScanEntry(memberName: 'Dilini Ratnayake',  litres: 60.0, points: 400, time: '9:22 AM'),
  ];

  int get _totalScans   => _recentScans.length;
  int get _totalPoints  => _recentScans.fold(0, (s, e) => s + e.points);
  int get _memberCount  => _recentScans.map((e) => e.memberName).toSet().length;

  @override
  Widget build(BuildContext context) {
    final rawId  = widget.employee.id.toUpperCase();
    final shortId = rawId.substring(0, rawId.length.clamp(0, 8));

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
                  Text('Welcome back,', style: AppTextStyles.caption),
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

            // ── Employee ID card ─────────────────────────────────────
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.badge_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text('Employee ID',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ]),
                const SizedBox(height: 8),
                Text('#$shortId',
                    style: AppTextStyles.h3
                        .copyWith(color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(widget.employee.name,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Scan Member button (only action) ─────────────────────
            Text('Quick Actions', style: AppTextStyles.h4),
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
                      Text('Scan Member QR', style: AppTextStyles.labelMedium),
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

            // ── Today's stats ────────────────────────────────────────
            Text("Today's Activity", style: AppTextStyles.h4),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _StatCard(
                  label: 'Scans', value: '$_totalScans',
                  icon: Icons.qr_code_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                  label: 'Points Given', value: '$_totalPoints',
                  icon: Icons.stars_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                  label: 'Members', value: '$_memberCount',
                  icon: Icons.people_outline_rounded)),
            ]),
            const SizedBox(height: 24),

            // ── Recent scans ─────────────────────────────────────────
            Text('Recent Scans', style: AppTextStyles.h4),
            const SizedBox(height: 14),
            ..._recentScans.map((s) => _RecentScanTile(scan: s)),
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
          Text('Scan Member QR', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Point the camera at the member\'s QR code to identify them.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Open Camera',
            icon: Icons.camera_alt_outlined,
            onPressed: () {
              Navigator.pop(context);
              // Simulate QR decode — show customer info sheet
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
    final member = _mockScannedMember;
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

          // Success indicator
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
          Text('Member Identified', style: AppTextStyles.h4),
          const SizedBox(height: 20),

          // Member info card
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
                  side: BorderSide(color: AppColors.border),
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
    final litresCtrl  = TextEditingController();
    final amountCtrl  = TextEditingController();

    // Points rate: 1 point per LKR 10 of fuel
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
          final litres = double.tryParse(litresCtrl.text) ?? 0;
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

              Row(children: [
                const Icon(Icons.local_gas_station_rounded,
                    color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 10),
                Text('Add Fuel Details', style: AppTextStyles.h4),
              ]),
              const SizedBox(height: 6),
              Text('For ${member.name}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),

              // Litres field
              AppTextField(
                label: 'Litres',
                hint: 'e.g. 30.5',
                controller: litresCtrl,
                prefixIconData: Icons.water_drop_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: 14),

              // Sale amount field
              AppTextField(
                label: 'Sale Amount (LKR)',
                hint: 'e.g. 7015',
                controller: amountCtrl,
                prefixIconData: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: 16),

              // Live points preview
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
                      side: BorderSide(color: AppColors.border),
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
                    onPressed: (litres > 0 && amount > 0)
                        ? () {
                            Navigator.pop(sheetCtx);
                            _onTransactionComplete(
                                context, member, litres, amount, points);
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
      double litres, double amount, int points) {
    // Add to recent scans
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period.name.toUpperCase()}';

    setState(() {
      _recentScans.insert(
        0,
        _ScanEntry(
          memberName: member.name,
          litres: litres,
          points: points,
          time: timeStr,
        ),
      );
    });

    // Success snackbar
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

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ScanEntry {
  final String memberName;
  final double litres;
  final int points;
  final String time;
  const _ScanEntry({
    required this.memberName,
    required this.litres,
    required this.points,
    required this.time,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.primaryLight, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  final _ScanEntry scan;
  const _RecentScanTile({required this.scan});

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
            const Icon(Icons.water_drop_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text('${scan.litres.toStringAsFixed(1)} L  •  ${scan.time}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
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