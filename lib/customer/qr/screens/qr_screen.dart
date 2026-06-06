import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';

class QrScreen extends ConsumerWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final qrData = jsonEncode({
      'userId': user.id,
      'name': user.name,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    // FIX 1: Safe substring — clamp to actual string length to avoid RangeError
    final rawId = user.id.toUpperCase();
    final shortId = rawId.substring(0, rawId.length.clamp(0, 8));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [

          // ── Header with back button ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('My QR Code', style: AppTextStyles.h3),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Text('Show this to staff to earn your points',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Avatar & name
                InitialsAvatar(initials: user.initials, size: 52),
                const SizedBox(height: 10),
                Text(user.name, style: AppTextStyles.h4),
                const SizedBox(height: 4),

                // FIX 1 applied: use safe shortId instead of raw substring(0, 8)
                Text('Member ID: #$shortId', style: AppTextStyles.caption),
                const SizedBox(height: 24),

                // QR code card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  // FIX 2: Use _CornerBracket (correct borders) instead of _Corner
                  child: Stack(children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(painter: _MockQrPainter()),
                    ),
                    const _CornerBracket(top: 0, left: 0, tl: true),
                    const _CornerBracket(top: 0, right: 0, tr: true),
                    const _CornerBracket(bottom: 0, left: 0, bl: true),
                    const _CornerBracket(bottom: 0, right: 0, br: true),
                  ]),
                ),
                const SizedBox(height: 8),
                const Text('Tap to refresh', style: AppTextStyles.caption),
                const SizedBox(height: 20),

                // Points summary bar
              

                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                 
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Corner bracket overlay (FIXED — was _Corner with all sides none) ─────────
class _CornerBracket extends StatelessWidget {
  final double? top, left, right, bottom;
  final bool tl, tr, bl, br;

  const _CornerBracket({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(color: AppColors.primary, width: 3);
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top:    (tl || tr) ? borderSide : BorderSide.none,
              bottom: (bl || br) ? borderSide : BorderSide.none,
              left:   (tl || bl) ? borderSide : BorderSide.none,
              right:  (tr || br) ? borderSide : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mock QR pattern painter ───────────────────────────────────────────────────
class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF0F0A1E);
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);
    _drawFinder(canvas, p, 10, 10, 50);
    _drawFinder(canvas, p, size.width - 60, 10, 50);
    _drawFinder(canvas, p, 10, size.height - 60, 50);
    final rng = <Offset>[
      const Offset(70, 10),  const Offset(80, 10),  const Offset(90, 10),
      const Offset(70, 20),  const Offset(82, 22),  const Offset(70, 32),
      const Offset(10, 70),  const Offset(22, 72),  const Offset(34, 70),
      const Offset(70, 70),  const Offset(80, 70),  const Offset(92, 72),
      const Offset(104, 70), const Offset(116, 70), const Offset(128, 72),
      const Offset(140, 70), const Offset(70, 82),  const Offset(82, 80),
      const Offset(70, 94),  const Offset(80, 92),  const Offset(92, 94),
      const Offset(70, 106), const Offset(82, 108), const Offset(70, 118),
      const Offset(80, 116), const Offset(92, 118), const Offset(104, 106),
      const Offset(116, 108),const Offset(128, 106),const Offset(140, 108),
      const Offset(70, 130), const Offset(80, 128), const Offset(92, 130),
      const Offset(104, 128),const Offset(116, 130),const Offset(128, 128),
      const Offset(140, 130),const Offset(152, 128),const Offset(70, 142),
      const Offset(82, 144), const Offset(94, 142), const Offset(106, 144),
      const Offset(118, 142),const Offset(130, 144),const Offset(142, 142),
      const Offset(70, 154), const Offset(80, 152), const Offset(92, 154),
      const Offset(104, 152),const Offset(116, 154),const Offset(130, 152),
    ];
    for (final o in rng) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 8, 8), p);
    }
  }

  void _drawFinder(
      Canvas canvas, Paint p, double x, double y, double s) {
    final border = Paint()
      ..color = const Color(0xFF0F0A1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(x, y, s, s), border);
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 10, s - 20, s - 20), p);
  }

  @override
  bool shouldRepaint(_) => false;
}