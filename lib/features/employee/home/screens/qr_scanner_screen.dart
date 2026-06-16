// lib/features/employee/screens/qr_scanner_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/emp_home_api_service.dart';
import '../data/emp_home_mock_service.dart';

class QrScannerScreen extends StatefulWidget {
  final String employeeId;
  final IEmpHomeService svc;

  const QrScannerScreen({
    super.key,
    required this.employeeId,
    required this.svc,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _loading = false;
  String? _error;

  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim =
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _scanning = true);
    });
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTapScan() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      const mockUserId = 'demo-qr';
      final member = await widget.svc.getMemberByQr(mockUserId);
      if (!mounted) return;
      Navigator.pop(context, member);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Dark background (replace with Camera widget) ───────────────
          _MockCameraBackground(scanning: _scanning),

          // ── Dimmed overlay with cut-out ────────────────────────────────
          _ScannerOverlay(),

          // ── Animated scan line inside the viewfinder ───────────────────
          if (_scanning)
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, __) => Stack(
                    children: [
                      Positioned(
                        top: _scanLineAnim.value * 240,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryLight,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top bar — close button pinned to top-right ─────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom instructions / tap-to-scan (mock) ──────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Point the camera at the member\'s QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _loading ? null : _onTapScan,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: _loading
                              ? null
                              : const LinearGradient(
                                  colors: AppColors.buttonGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: _loading
                              ? Colors.white.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Scan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mock camera background ─────────────────────────────────────────────────────

class _MockCameraBackground extends StatelessWidget {
  final bool scanning;
  const _MockCameraBackground({required this.scanning});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: scanning ? const Color(0xFF0A0A12) : Colors.black,
      child: Center(
        child: scanning
            ? Opacity(
                opacity: 0.15,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: 120,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ── Scanner viewfinder overlay ─────────────────────────────────────────────────

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const viewfinderSize = 260.0;
    final screenSize = MediaQuery.of(context).size;
    final hPad = (screenSize.width - viewfinderSize) / 2;
    final vOffset = screenSize.height * 0.15;

    return CustomPaint(
      painter: _OverlayPainter(
        viewfinderRect: Rect.fromLTWH(
            hPad, vOffset, viewfinderSize, viewfinderSize),
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(
              0,
              -(screenSize.height * 0.5 -
                  vOffset -
                  viewfinderSize / 2)),
          child: SizedBox(
            width: viewfinderSize,
            height: viewfinderSize,
            child: _CornerBrackets(),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect viewfinderRect;
  const _OverlayPainter({required this.viewfinderRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.75);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, viewfinderRect.top), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, viewfinderRect.bottom, size.width,
            size.height - viewfinderRect.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(0, viewfinderRect.top, viewfinderRect.left,
            viewfinderRect.height),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(viewfinderRect.right, viewfinderRect.top,
            size.width - viewfinderRect.right, viewfinderRect.height),
        paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.viewfinderRect != viewfinderRect;
}

class _CornerBrackets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const strokeWidth = 3.5;
    const cornerLength = 24.0;
    final color = AppColors.primaryLight;

    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? 0 : null,
        bottom: top ? null : 0,
        left: left ? 0 : null,
        right: left ? null : 0,
        child: CustomPaint(
          size: const Size(
              cornerLength + strokeWidth, cornerLength + strokeWidth),
          painter: _CornerPainter(
            top: top,
            left: left,
            color: color,
            strokeWidth: strokeWidth,
            length: cornerLength,
          ),
        ),
      );
    }

    return Stack(children: [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ]);
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;
  final double strokeWidth;
  final double length;

  const _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.strokeWidth,
    required this.length,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? strokeWidth / 2 : size.width - strokeWidth / 2;
    final y = top ? strokeWidth / 2 : size.height - strokeWidth / 2;
    final xEnd = left
        ? strokeWidth / 2 + length
        : size.width - strokeWidth / 2 - length;
    final yEnd = top
        ? strokeWidth / 2 + length
        : size.height - strokeWidth / 2 - length;

    canvas.drawLine(Offset(x, y), Offset(xEnd, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, yEnd), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}