// lib/features/employee/screens/fuel_entry_sheet.dart
//
// Bottom sheet for entering a fuel sale amount and awarding points.
// Extracted from employee_home_page.dart to keep files small.
//
// Usage (inside an async function):
//   final confirmed = await showModalBottomSheet<bool>(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: AppColors.bgCard,
//     shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//     builder: (_) => FuelEntrySheet(
//       member: member, employeeId: employeeId, svc: svc),
//   );
//   if (confirmed == true) { /* reload */ }

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../data/emp_home_api_service.dart';

class FuelEntrySheet extends StatefulWidget {
  final ScannedMember member;
  final String employeeId;
  final IEmpHomeService svc;

  const FuelEntrySheet({
    super.key,
    required this.member,
    required this.employeeId,
    required this.svc,
  });

  @override
  State<FuelEntrySheet> createState() => _FuelEntrySheetState();
}

class _FuelEntrySheetState extends State<FuelEntrySheet> {
  final _amountCtrl = TextEditingController();
  bool _confirming = false;

  static const double _pointsPerLkr = 0.1;

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  int get _points => (_amount * _pointsPerLkr).toInt();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_amount <= 0 || _confirming) return;
    setState(() => _confirming = true);
    try {
      final earnedPoints = await widget.svc.recordFuelSale(
        employeeId: widget.employeeId,
        customerId: widget.member.userId,
        saleAmount: _amount,
        pointsAwarded: _points,
      );
      if (mounted) Navigator.pop(context, earnedPoints > 0 ? earnedPoints : true);
    } catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station_rounded,
                color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Fuel Sale', style: AppTextStyles.h4),
            Text('For ${widget.member.name}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
          ]),
        ]),
        const SizedBox(height: 20),

        // Amount input
        StatefulBuilder(
          builder: (_, setInner) => Column(children: [
            AppTextField(
              label: 'Sale Amount',
              hint: 'e.g. 7015',
              controller: _amountCtrl,
              prefixIconData: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) {
                setInner(() {});
                setState(() {});
              },
            ),
            
          ]),
        ),

        const SizedBox(height: 20),

        // Actions
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
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
              label: _confirming ? 'Confirming…' : 'Confirm',
              icon: Icons.check_rounded,
              onPressed: (_amount > 0 && !_confirming) ? _confirm : null,
            ),
          ),
        ]),
      ]),
    );
  }
}