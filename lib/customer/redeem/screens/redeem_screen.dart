import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/models/offer_models.dart';
import 'package:loyalty_app/customer/redeem/data/redeem_api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';


class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key});

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  late Future<List<OfferModel>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = redeemService.getOffers();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Redeem Points', style: AppTextStyles.h3),
          ),
          const SizedBox(height: 16),

          // Balance bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.cardGradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Available to redeem',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.75))),
                  const SizedBox(height: 4),
                  Text('${user.totalPoints} pts', style: AppTextStyles.h2),
                ]),
                const Spacer(),
                const Icon(Icons.card_giftcard_rounded,
                  size: 38, color: Colors.white24),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Available offers', style: AppTextStyles.h4),
          ),
          const SizedBox(height: 12),

          // Offers list
          Expanded(
            child: FutureBuilder<List<OfferModel>>(
              future: _offersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryLight),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load offers',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted),
                    ),
                  );
                }
                final offers = snapshot.data ?? [];
                if (offers.isEmpty) {
                  return Center(
                    child: Text(
                      'No offers available',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _OfferCard(
                    offer: offers[i],
                    canAfford: user.totalPoints >= offers[i].pointsCost,
                    onTap: () => _showConfirmSheet(context, offers[i]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showConfirmSheet(BuildContext context, OfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(offer: offer),
    );
  }
}

// ─── Offer card ───────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool canAfford;
  final VoidCallback onTap;

  const _OfferCard({
    required this.offer, required this.canAfford, required this.onTap,
  });

  Color get _bizColor {
    if (offer.business == 'Fuel Station') return AppColors.fuelColor;
    if (offer.business == 'Laundry') return AppColors.laundryColor;
    if (offer.business == 'Gold House') return AppColors.golfColor;
    return AppColors.golfColor;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      BusinessIcon(business: offer.business, size: 50),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(offer.title, style: AppTextStyles.labelMedium),
        const SizedBox(height: 2),
        Text('${offer.business} · ${offer.description}',
          style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text('${offer.pointsCost} pts',
          style: AppTextStyles.labelSmall.copyWith(color: _bizColor)),
      ])),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: canAfford ? onTap : null,
        child: AnimatedOpacity(
          opacity: canAfford ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: canAfford
                  ? const LinearGradient(colors: AppColors.buttonGradient)
                  : null,
              color: canAfford ? null : AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Redeem',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
          ),
        ),
      ),
    ]),
  );
}

// ─── Confirmation bottom sheet ────────────────────────────────────────────────
class _ConfirmSheet extends ConsumerStatefulWidget {
  final OfferModel offer;
  const _ConfirmSheet({required this.offer});

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  bool _loading = false;

  Future<void> _confirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider)!;
    try {
      final code = await redeemService.redeemOffer(user.id, widget.offer, points: user.totalPoints);
      ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => RedeemSuccessScreen(
          offer: widget.offer, code: code)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    final after = user.totalPoints - widget.offer.pointsCost;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Drag handle
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border,
            borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 24),

        BusinessIcon(business: widget.offer.business, size: 64),
        const SizedBox(height: 14),
        Text(widget.offer.title, style: AppTextStyles.h3, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('${widget.offer.business} · ${widget.offer.description}',
          style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 22),

        // Summary box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDark, borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _SummaryRow(label: 'Your balance', value: '${user.totalPoints} pts',
              valueColor: AppColors.textPrimary),
            const SizedBox(height: 10),
            _SummaryRow(label: 'Cost', value: '-${widget.offer.pointsCost} pts',
              valueColor: AppColors.error),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.border.withValues(alpha: 0.6), height: 1),
            ),
            _SummaryRow(label: 'After redemption', value: '$after pts',
              valueColor: AppColors.success, bold: true),
          ]),
        ),
        const SizedBox(height: 22),

        GradientButton(
          label: _loading ? 'Processing…' : 'Confirm Redemption',
          icon: Icons.check_rounded,
          onPressed: _loading ? null : _confirm,
        ),
        const SizedBox(height: 10),
        GhostButton(
          label: 'Cancel',
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final bool bold;
  const _SummaryRow({required this.label, required this.value,
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

// ─── Redemption success screen ────────────────────────────────────────────────
class RedeemSuccessScreen extends StatelessWidget {
  final OfferModel offer;
  final String code;

  const RedeemSuccessScreen({super.key, required this.offer, required this.code});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          // Success circle
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.35), width: 2),
            ),
            child: const Icon(Icons.check_rounded,
              color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 22),

          const Text('Redeemed!', style: AppTextStyles.h1),
          const SizedBox(height: 10),
          Text(
            'Your ${offer.title.toLowerCase()} has been confirmed.\nShow the code below to the staff.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              BusinessIcon(business: offer.business, size: 52),
              const SizedBox(height: 14),
              Text(offer.title, style: AppTextStyles.h4),
              const SizedBox(height: 6),
              Text(offer.business, style: AppTextStyles.caption),
              const SizedBox(height: 20),
              const Text('Redemption code', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Text(code, style: AppTextStyles.h1.copyWith(
                color: AppColors.primary, letterSpacing: 6, fontSize: 30)),
              const SizedBox(height: 8),
              const Text('Valid for 24 hours', style: AppTextStyles.caption),
            ]),
          ),
          const SizedBox(height: 28),

          GradientButton(
            label: 'Back to Home',
            icon: Icons.home_rounded,
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ]),
      ),
    ),
  );
}
