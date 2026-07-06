import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';

class QrScreen extends ConsumerWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // phone is the primary key used by the employee scanner to look up the member
    final qrData = jsonEncode({
      'phone': user.phone,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 16, 0),
            child: Row(children: [
             SizedBox(width: 15),
              Text('My QR Code', style: AppTextStyles.h3),
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
                  child: Stack(children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F0A1E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F0A1E),
                      ),
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

