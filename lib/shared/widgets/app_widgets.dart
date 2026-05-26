import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';


// ─── Gradient Button ──────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> colors;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key, required this.label, this.onPressed,
    this.isLoading = false, this.colors = AppColors.buttonGradient,
    this.height = 54, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: onPressed == null
                ? [Colors.grey.shade700, Colors.grey.shade800] : colors),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(width:22, height:22,
                  child: CircularProgressIndicator(strokeWidth:2.5, color:Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (icon != null) ...[Icon(icon, color:Colors.white, size:20), const SizedBox(width:8)],
                  Text(label, style: AppTextStyles.labelLarge),
                ]),
        ),
      ),
    );
  }
}

// ─── Ghost Button ─────────────────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      height: 50, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
    ),
  );
}

// ─── App Text Field ───────────────────────────────────────────────────────────
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIconData;
  final bool readOnly;
  final void Function(String)? onChanged;
  final int? maxLength;
  final TextInputAction textInputAction;

  const AppTextField({
    super.key, required this.label, this.hint, this.controller,
    this.isPassword = false, this.keyboardType = TextInputType.text,
    this.validator, this.prefixIconData, this.readOnly = false,
    this.onChanged, this.maxLength, this.textInputAction = TextInputAction.next,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        maxLength: widget.maxLength,
        textInputAction: widget.textInputAction,
        style: AppTextStyles.bodyMedium,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          counterText: '',
          prefixIcon: widget.prefixIconData != null
              ? Icon(widget.prefixIconData, color: AppColors.textHint, size: 20)
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    ],
  );
}

// ─── OTP Input Field ──────────────────────────────────────────────────────────
class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final bool hasError;

  const OtpBox({
    super.key, required this.controller, required this.focusNode,
    this.nextFocus, this.hasError = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64, height: 70,
    child: TextFormField(
      controller: controller, focusNode: focusNode,
      keyboardType: TextInputType.number, textAlign: TextAlign.center,
      maxLength: 1, style: AppTextStyles.h2,
      decoration: InputDecoration(
        counterText: '',
        contentPadding: EdgeInsets.zero,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      onChanged: (val) {
        if (val.length == 1 && nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else if (val.isEmpty) FocusScope.of(context).previousFocus();
      },
    ),
  );
}

// ─── App Logo ─────────────────────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF5A3FD4), Color(0xFF9B30C8)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * 0.24),
    ),
    child: Icon(Icons.stars_rounded, color: Colors.white, size: size * 0.55),
  );
}

// ─── Avatar Initials ──────────────────────────────────────────────────────────
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const InitialsAvatar({super.key, required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF5A3FD4), Color(0xFF9B30C8)]),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(initials, style: TextStyle(
      fontFamily: 'Poppins', fontSize: size * 0.34,
      fontWeight: FontWeight.w700, color: Colors.white,
    )),
  );
}

// ─── Card Container ───────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    ),
  );
}

// ─── Business Icon ────────────────────────────────────────────────────────────
class BusinessIcon extends StatelessWidget {
  final String business;
  final double size;

  const BusinessIcon({super.key, required this.business, this.size = 40});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; IconData icon;
    switch (business) {
      case 'Fuel Station':
        bg = AppColors.fuelColor.withValues(alpha: 0.15);
        fg = AppColors.fuelColor;
        icon = Icons.local_gas_station;
        break;
      case 'Laundry':
        bg = AppColors.laundryColor.withValues(alpha: 0.15);
        fg = AppColors.laundryColor;
        icon = Icons.local_laundry_service;
        break;
      case 'Gold Shop':
        bg = AppColors.golfColor.withValues(alpha: 0.15);
        fg = AppColors.golfColor;
        icon = Icons.diamond_rounded;  // ← diamond icon
        break;
      default:
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        icon = Icons.star;
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

// ─── Tier Badge ───────────────────────────────────────────────────────────────
class TierBadge extends StatelessWidget {
  final String tier;
  const TierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.military_tech_rounded, color: AppColors.accentGold, size: 14),
        const SizedBox(width: 4),
        Text(tier, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentGold)),
      ]),
    );
  }
}

// ─── Demo Hint Box ────────────────────────────────────────────────────────────
class DemoHintBox extends StatelessWidget {
  const DemoHintBox({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.accentGold.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.lightbulb_outline, color: AppColors.accentGold, size: 15),
        const SizedBox(width: 7),
        Text('Demo credentials', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentGold)),
      ]),
      const SizedBox(height: 7),
      Text('Employee Email: employee@gmail.com\nCustomer Email: customer@gmail.com\nPassword: any 6+ characters\nPhone: 0771234567  ·  OTP: 1234',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accentGold.withValues(alpha: 0.85), height: 1.7)),
    ]),
  );
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 17),
      const SizedBox(width: 9),
      Expanded(child: Text(message,
        style: AppTextStyles.caption.copyWith(color: AppColors.error))),
    ]),
  );
}

// ─── Divider with text ────────────────────────────────────────────────────────
class DividerText extends StatelessWidget {
  final String text;
  const DividerText({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: AppColors.border)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(text, style: AppTextStyles.caption),
    ),
    const Expanded(child: Divider(color: AppColors.border)),
  ]);
}

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.bar_chart_rounded, 'Points'),
      (Icons.qr_code_rounded, 'My QR'),
      (Icons.person_rounded, 'Profile'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(items[i].$1,
                color: active ? AppColors.primary : AppColors.textHint, size: 24),
              const SizedBox(height: 3),
              Text(items[i].$2, style: AppTextStyles.caption.copyWith(
                color: active ? AppColors.primary : AppColors.textHint,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
              if (active) ...[
                const SizedBox(height: 3),
                Container(width:5,height:5,decoration:const BoxDecoration(
                  color:AppColors.primary, shape:BoxShape.circle)),
              ],
            ]),
          );
        }),
      ),
    );
  }
}