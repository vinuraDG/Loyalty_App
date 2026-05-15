import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../services/mock_points_service.dart';
import '../../../models/user_model.dart';
import '../../../services/mock_auth_service.dart';
import '../../../core/constants/app_constants.dart';

// ════════════════════════════════════════════════════════════════
//  EMPLOYEE DASHBOARD
// ════════════════════════════════════════════════════════════════

class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboardScreen> {
  // Selected business to award points for
  String _selectedBusiness = AppConstants.businessFuel;

  final _businesses = const [
    (AppConstants.businessFuel, Icons.local_gas_station_rounded, AppColors.fuelColor),
    (AppConstants.businessLaundry, Icons.local_laundry_service_rounded, AppColors.laundryColor),
    (AppConstants.businessGold, Icons.diamond, AppColors.accentGold),
  ];

  // Today's mock stats
  int get _todayPoints => 2460;
  int get _todayCustomers => 5;

  // Recent awards from mock service (last 3 of demo-001)
  List<dynamic> get _recentAwards =>
      MockPointsService.instance.getForUser('cust-001').take(3).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDeep,
    body: SafeArea(
      child: Column(children: [

        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Employee Dashboard',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              const Text('Nimal Silva', style: AppTextStyles.h4),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.circle, color: AppColors.success, size: 8),
                const SizedBox(width: 6),
                Text('On duty',
                  style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Today stats ──────────────────────────────────────
              Row(children: [
                _StatBox(label: 'Points awarded today',
                  value: '$_todayPoints', color: AppColors.success),
                const SizedBox(width: 10),
                _StatBox(label: 'Customers served',
                  value: '$_todayCustomers', color: AppColors.primary),
              ]),
              const SizedBox(height: 20),

              // ── Business selector ─────────────────────────────────
              Text('Select business', style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Row(children: _businesses.map((b) {
                final selected = _selectedBusiness == b.$1;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(
                    right: b.$1 == AppConstants.businessGold ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBusiness = b.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? b.$3 : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Icon(b.$2, color: selected ? b.$3 : AppColors.textMuted, size: 26),
                        const SizedBox(height: 6),
                        Text(_shortName(b.$1),
                          style: AppTextStyles.caption.copyWith(
                            color: selected ? b.$3 : AppColors.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          )),
                      ]),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 20),

              // ── Scan button ───────────────────────────────────────
              GradientButton(
                label: 'Scan Customer QR',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EmployeeScannerScreen(
                    business: _selectedBusiness,
                    points: _pointsFor(_selectedBusiness),
                  )),
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent awards ─────────────────────────────────────
              Text('Recent awards', style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted)),
              const SizedBox(height: 10),
              ..._recentAwards.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    BusinessIcon(business: tx.business, size: 38),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kasun Perera', style: AppTextStyles.labelMedium.copyWith(fontSize: 13)),
                      Text('${tx.business} · ${_fmtTime(tx.date)}',
                        style: AppTextStyles.caption),
                    ])),
                    Text(tx.displayPoints,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: tx.isEarned ? AppColors.success : AppColors.error)),
                  ]),
                ),
              )),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    ),
  );

  String _shortName(String b) {
    if (b == AppConstants.businessFuel) return 'Fuel';
    return b;
  }

  int _pointsFor(String b) {
    if (b == AppConstants.businessFuel) return AppConstants.fuelPoints;
    if (b == AppConstants.businessLaundry) return AppConstants.laundryPoints;
    return AppConstants.goldPoints;
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.caption, maxLines: 2),
      const SizedBox(height: 6),
      Text(value, style: AppTextStyles.h2.copyWith(color: color)),
    ]),
  ));
}

// ════════════════════════════════════════════════════════════════
//  EMPLOYEE QR SCANNER SCREEN
// ════════════════════════════════════════════════════════════════

class EmployeeScannerScreen extends StatefulWidget {
  final String business;
  final int points;

  const EmployeeScannerScreen({
    super.key, required this.business, required this.points,
  });

  @override
  State<EmployeeScannerScreen> createState() => _EmployeeScannerState();
}

class _EmployeeScannerState extends State<EmployeeScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

  void _simulateScan() {
    // In real app: use mobile_scanner package to decode actual QR
    // Here we simulate scanning cust-001
    final user = MockAuthService.instance.findById('cust-001');
    if (user == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmployeeAwardSuccessScreen(
        user: user, business: widget.business, points: widget.points,
      )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(children: [

        // Header on dark bg
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text('Scan Customer QR',
              style: AppTextStyles.h4.copyWith(color: Colors.white)),
          ]),
        ),

        // Camera preview area (simulated)
        Expanded(
          child: Stack(alignment: Alignment.center, children: [

            // Dark camera grid overlay
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
            ),

            // Scan frame
            SizedBox(
              width: 240, height: 240,
              child: Stack(children: [
                // Corner brackets
                ...[
                  [0.0, 0.0, true, false, false, false],
                  [0.0, null, false, true, false, false],
                  [null, 0.0, false, false, true, false],
                  [null, null, false, false, false, true],
                ].map((v) => Positioned(
                  top: v[0] as double?,
                  right: v[1] as double?,
                  bottom: v[2] == true ? null : (v[4] == true || v[5] == true ? 0.0 : null),
                  left: v[3] == true ? null : (v[0] != null || v[2] == true ? 0.0 : null),
                  child: SizedBox(
                    width: 36, height: 36,
                    child: CustomPaint(painter: _BracketPainter(
                      topLeft: v[0] != null && v[1] == null,
                      topRight: v[0] != null && v[1] != null,
                      bottomLeft: v[0] == null && v[1] == null && v[4] != true,
                      bottomRight: v[5] == true,
                    )),
                  ),
                )),

                // Animated scan line
                AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) => Positioned(
                    top: _scanAnim.value * 230,
                    left: 0, right: 0,
                    child: Container(height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          AppColors.primary.withOpacity(0.8),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // Instruction text
            Positioned(
              bottom: 120,
              child: Text('Point camera at customer\'s QR code',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
            ),

            // Business info pill
            Positioned(
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  BusinessIcon(business: widget.business, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.business} · +${widget.points} pts',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentGold, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
          ]),
        ),

        // Simulate button
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.bgDeep,
          child: GradientButton(
            label: 'Simulate Successful Scan',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _simulateScan,
          ),
        ),
      ]),
    ),
  );
}

class _BracketPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  const _BracketPainter({
    this.topLeft = false, this.topRight = false,
    this.bottomLeft = false, this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (topLeft) {
      canvas.drawLine(const Offset(0, 20), const Offset(0, 0), p);
      canvas.drawLine(const Offset(0, 0), const Offset(20, 0), p);
    }
    if (topRight) {
      canvas.drawLine(Offset(s.width, 20), Offset(s.width, 0), p);
      canvas.drawLine(Offset(s.width, 0), Offset(s.width - 20, 0), p);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, s.height - 20), Offset(0, s.height), p);
      canvas.drawLine(Offset(0, s.height), Offset(20, s.height), p);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(s.width, s.height - 20), Offset(s.width, s.height), p);
      canvas.drawLine(Offset(s.width, s.height), Offset(s.width - 20, s.height), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════
//  AWARD SUCCESS SCREEN
// ════════════════════════════════════════════════════════════════

class EmployeeAwardSuccessScreen extends StatelessWidget {
  final UserModel user;
  final String business;
  final int points;

  const EmployeeAwardSuccessScreen({
    super.key, required this.user,
    required this.business, required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // Award the points in mock service
    MockPointsService.instance.awardPoints(user.id, business, points);
    final newTotal = (MockAuthService.instance.findById(user.id)?.totalPoints ?? 0);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Success circle
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.35), width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 22),

              const Text('Points Awarded!', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              const Text('Points successfully added to customer account.',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 28),

              // Customer card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  InitialsAvatar(initials: user.initials, size: 56),
                  const SizedBox(height: 12),
                  Text(user.name, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('#${user.id.toUpperCase().substring(0, 8)}',
                    style: AppTextStyles.caption),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  _Row(label: 'Business', value: business,
                    valueColor: _bizColor(business)),
                  const SizedBox(height: 10),
                  _Row(label: 'Points awarded',
                    value: '+$points pts', valueColor: AppColors.success),
                  const SizedBox(height: 10),
                  _Row(label: 'New balance',
                    value: '$newTotal pts', valueColor: AppColors.textPrimary, bold: true),
                ]),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Done',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bizColor(String b) {
    if (b == AppConstants.businessFuel) return AppColors.fuelColor;
    if (b == AppConstants.businessLaundry) return AppColors.laundryColor;
    return AppColors.golfColor;
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final bool bold;
  const _Row({required this.label, required this.value,
    required this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyles.bodySmall),
      Text(value, style: AppTextStyles.labelMedium.copyWith(
        color: valueColor,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      )),
    ],
  );
}