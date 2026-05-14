import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';

enum UserTier { bronze, silver, gold, platinum }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool secondary;
  const AppButton({super.key, required this.label,
    this.onTap, this.isLoading=false, this.secondary=false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: secondary ? Colors.white : AppColors.primary,
        foregroundColor: secondary ? AppColors.primary : Colors.white,
        side: secondary ? const BorderSide(color: AppColors.primary) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
        ? const SizedBox(width:22,height:22,
            child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
        : Text(label, style: const TextStyle(
            fontFamily:'Poppins', fontSize:15, fontWeight:FontWeight.w600)),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final String? error;
  final TextInputType keyboardType;
  const AppTextField({super.key, required this.hint,
    required this.controller, this.obscure=false,
    this.error, this.keyboardType=TextInputType.text});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: AppTextStyles.body,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption,
      errorText: error,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
  );
}

class PointsBadge extends StatelessWidget {
  final int points;
  const PointsBadge({super.key, required this.points});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal:12,vertical:6),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize:MainAxisSize.min, children:[
      const Icon(Icons.star_rounded, size:16, color:AppColors.primary),
      const SizedBox(width:4),
      Text('$points pts',
        style: const TextStyle(fontFamily:'Poppins',
          fontSize:13, fontWeight:FontWeight.w600, color:AppColors.primary)),
    ]),
  );
}

class TierChip extends StatelessWidget {
  final UserTier tier;
  const TierChip({super.key, required this.tier});
  static const _colors = {
    UserTier.bronze:   Color(0xFFCD7F32),
    UserTier.silver:   Color(0xFF9E9E9E),
    UserTier.gold:     Color(0xFFFFC107),
    UserTier.platinum: Color(0xFF78909C),
  };
  @override
  Widget build(BuildContext context) {
    final c = _colors[tier]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(tier.name.toUpperCase(),
        style: TextStyle(fontFamily:'Poppins',
          fontSize:11, fontWeight:FontWeight.w700, color:c)),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const TransactionTile({super.key, required this.tx});
  @override
  Widget build(BuildContext context) {
    final isEarn = tx.isEarning;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal:0,vertical:2),
      leading: CircleAvatar(
        backgroundColor: isEarn
          ? AppColors.primary.withOpacity(0.12)
          : Colors.red.withOpacity(0.1),
        child: Icon(isEarn ? Icons.add_rounded : Icons.remove_rounded,
          size:20, color: isEarn ? AppColors.primary : Colors.red),
      ),
      title: Text(tx.description, style:AppTextStyles.body),
      subtitle: Text(
        '${tx.date.day}/${tx.date.month}/${tx.date.year}',
        style: AppTextStyles.caption),
      trailing: Text(
        '${isEarn ? '+' : ''}${tx.points} pts',
        style: TextStyle(fontFamily:'Poppins',fontSize:14,
          fontWeight:FontWeight.w600,
          color: isEarn ? AppColors.primary : Colors.red)),
    );
  }
}