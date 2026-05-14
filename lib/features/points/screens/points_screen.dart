import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/mock_points_service.dart';
import '../../../models/transaction_model.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});
  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Fuel Station', 'Laundry', 'Gold'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final svc  = MockPointsService.instance;
    final all  = svc.getForUser(user.id);
    final txs  = _filter == 'All'
        ? all : all.where((t) => t.business == _filter).toList();
    final byBiz = svc.getEarnedByBusiness(user.id);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [

          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('My Points', style: AppTextStyles.h3),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Balance card
              Container(
                width: double.infinity, padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total balance', style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 4),
                  Text('${user.totalPoints}',
                    style: AppTextStyles.display.copyWith(fontSize: 40)),
                  Text('points', style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 14),
                  Row(children: [
                    _StatChip(label: 'Earned', value: '+${svc.getTotalEarned(user.id)}',
                      color: AppColors.success),
                    const SizedBox(width: 20),
                    _StatChip(label: 'Redeemed', value: '-${svc.getTotalRedeemed(user.id)}',
                      color: AppColors.laundryColor),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              // Per-business breakdown
              Row(children: [
                _BizCard(business: 'Fuel Station', pts: byBiz['Fuel Station'] ?? 0),
                const SizedBox(width: 8),
                _BizCard(business: 'Laundry', pts: byBiz['Laundry'] ?? 0),
                const SizedBox(width: 8),
                _BizCard(business: 'Gold', pts: byBiz['Gold'] ?? 0),
              ]),
              const SizedBox(height: 20),

              Text('All transactions', style: AppTextStyles.h4),
              const SizedBox(height: 12),

              // Filter chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: sel ? const LinearGradient(colors: AppColors.buttonGradient) : null,
                          color: sel ? null : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Colors.transparent : AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(f, style: AppTextStyles.labelSmall.copyWith(
                          color: sel ? Colors.white : AppColors.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              if (txs.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No transactions found.', style: AppTextStyles.bodySmall),
                ))
              else
                ...txs.map((tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TxCard(tx: tx),
                )),

              const SizedBox(height: 20),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.6))),
    Text(value, style: AppTextStyles.h4.copyWith(color: color)),
  ]);
}

class _BizCard extends StatelessWidget {
  final String business;
  final int pts;
  const _BizCard({required this.business, required this.pts});

  Color get _color {
    if (business == 'Fuel Station') return AppColors.fuelColor;
    if (business == 'Laundry') return AppColors.laundryColor;
    if (business == 'Gold') return AppColors.accentGold;
    return AppColors.accentGold;
  }

  String get _shortName {
    if (business == 'Fuel Station') return 'Fuel';
    return business;
  }

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _color.withOpacity(0.5)),
    ),
    child: Column(children: [
      Text(_shortName, style: AppTextStyles.caption.copyWith(
        color: _color, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('$pts', style: AppTextStyles.h4),
      Text('pts', style: AppTextStyles.caption),
    ]),
  ));
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
      BusinessIcon(business: tx.business, size: 44),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tx.business, style: AppTextStyles.labelMedium),
        const SizedBox(height: 2),
        Text(
          '${tx.isEarned ? 'Earned' : 'Redeemed'} · ${_fmt(tx.date)}',
          style: AppTextStyles.caption),
      ])),
      Text(tx.displayPoints, style: AppTextStyles.labelMedium.copyWith(
        color: tx.isEarned ? AppColors.success : AppColors.error)),
    ]),
  );

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 24) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}