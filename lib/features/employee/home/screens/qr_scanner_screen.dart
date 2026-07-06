// lib/features/employee/screens/qr_scanner_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/emp_home_api_service.dart';

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
  bool _loading  = false;
  bool _detected = false; // prevent double-triggers
  String? _error;

  late final MobileScannerController _scanController;
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanController = MobileScannerController();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim =
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(String rawValue) async {
    if (_loading || _detected) return;
    setState(() {
      _loading  = true;
      _detected = true;
      _error    = null;
    });

    // Extract phone from JSON payload  {phone: ..., name: ..., ts: ...}
    // Fall back to treating the raw value as a plain phone number
    String phone;
    try {
      final map = jsonDecode(rawValue) as Map<String, dynamic>;
      phone = (map['phone'] ?? map['userId'] ?? rawValue).toString();
    } catch (_) {
      phone = rawValue;
    }

    try {
      final member = await widget.svc.getMemberByQr(phone);
      if (!mounted) return;
      Navigator.pop(context, member);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e.toString();
        _loading  = false;
        _detected = false; // allow retry
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
          // ── Live camera feed ──────────────────────────────────────────
          MobileScanner(
            controller: _scanController,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final raw = capture.barcodes.first.rawValue;
                if (raw != null) _onQrDetected(raw);
              }
            },
          ),

          // ── Dimmed overlay with cut-out ────────────────────────────────
          _ScannerOverlay(),

          // ── Animated scan line inside the viewfinder ───────────────────
          if (!_loading)
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

          // ── Bottom status / instructions ───────────────────────────────
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
                      _loading
                          ? 'Looking up member...'
                          : 'Point the camera at the member\'s QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 20),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
