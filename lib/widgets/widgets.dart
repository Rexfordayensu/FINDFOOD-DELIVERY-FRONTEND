import 'package:flutter/material.dart';
import '../theme.dart';

// ─── PRIMARY BUTTON ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label,
      this.onPressed, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.black),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ─── GHOST BUTTON ─────────────────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary(context),
          side: BorderSide(color: AppColors.border(context)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label),
      ),
    );
  }
}

// ─── TEXT FIELD ───────────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;

  const AppTextField({
    super.key, required this.controller, required this.hint,
    this.prefixIcon, this.suffixIcon, this.obscure = false,
    this.keyboardType, this.validator, this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textHint(context), size: 20)
            : null,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title,
      this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppText.heading.copyWith(
                  color: AppColors.textPrimary(context))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.label.copyWith(color: AppTheme.accent)),
            ),
        ],
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':          return AppTheme.warning;
      case 'preparing':        return AppTheme.accent;
      case 'ready':            return AppTheme.success;
      case 'out_for_delivery': return AppTheme.accent;
      case 'delivered':        return AppTheme.success;
      default:                 return const Color(0xFF9E9E9E);
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'pending':          return 'Pending';
      case 'preparing':        return 'Preparing';
      case 'ready':            return 'Ready';
      case 'out_for_delivery': return 'On the way';
      case 'delivered':        return 'Delivered';
      default:                 return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(_label,
          style: TextStyle(color: _color, fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── RESTAURANT CARD ──────────────────────────────────────────────────────────
class RestaurantCard extends StatelessWidget {
  final String name, cuisine, address;
  final bool isActive;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key, required this.name, required this.cuisine,
    required this.address, required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor   = AppColors.card(context);
    final borderColor = AppColors.border(context);
    final textPri     = AppColors.textPrimary(context);
    final textSec     = AppColors.textSecondary(context);
    final textHint    = AppColors.textHint(context);
    final surfColor   = AppColors.surface(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.storefront_rounded,
                    size: 48, color: textHint),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name,
                            style: AppText.title.copyWith(color: textPri),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.success.withValues(alpha: 0.12)
                              : textHint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: isActive ? AppTheme.success : textHint,
                            fontSize: 11, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(cuisine,
                      style: AppText.body.copyWith(color: textSec)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: textHint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(address,
                            style: AppText.caption.copyWith(color: textHint),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppTheme.accent),
                      const SizedBox(width: 2),
                      const Text('4.8',
                          style: TextStyle(
                              color: AppTheme.accent, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: textHint),
                      const SizedBox(width: 2),
                      Text('25 min',
                          style: AppText.caption.copyWith(color: textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MENU ITEM CARD ───────────────────────────────────────────────────────────
class MenuItemCard extends StatelessWidget {
  final String name, price;
  final String? description;
  final bool isAvailable;
  final VoidCallback onAdd;
  final Future<void> Function() onDelete;
  const MenuItemCard({
    super.key, required this.name, this.description,
    required this.price, required this.isAvailable, required this.onAdd, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor   = AppColors.card(context);
    final borderColor = AppColors.border(context);
    final textPri     = AppColors.textPrimary(context);
    final textSec     = AppColors.textSecondary(context);
    final textHint    = AppColors.textHint(context);
    final surfColor   = AppColors.surface(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppText.title.copyWith(color: textPri)),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description!,
                      style: AppText.body.copyWith(color: textSec),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Text(price,
                    style: AppText.title.copyWith(color: AppTheme.accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: surfColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.fastfood_rounded,
                      size: 30, color: textHint),
                ),
              ),
              const SizedBox(height: 8),
              if (isAvailable)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Add',
                          style: TextStyle(color: Colors.black,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                )
              else
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: textHint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('Sold out',
                        style: TextStyle(color: textHint, fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.icon, required this.title,
    required this.subtitle, this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint(context)),
            const SizedBox(height: 16),
            Text(title,
                style: AppText.heading.copyWith(
                    color: AppColors.textPrimary(context)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppText.body.copyWith(
                    color: AppColors.textSecondary(context)),
                textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}