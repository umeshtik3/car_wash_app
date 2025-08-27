import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Base button mirroring CSS `.button.primary` and `.button.text` patterns.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;
  final IconData? leadingIcon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.loading = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label),
        if (loading) ...[
          const SizedBox(width: AppSpacing.sm),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );

    if (primary) {
      return ElevatedButton(onPressed: loading ? null : onPressed, child: child);
    }
    return TextButton(onPressed: loading ? null : onPressed, child: child);
  }
}

/// Text field wrapper mirroring `.input` styles and invalid/selected states.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final Widget? suffix;
  final Widget? prefix;
  final bool enabled;
  final int? maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: prefix,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

/// Card container following `.card` style with medium radius and small shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.xl)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.medium,
        boxShadow: AppShadows.small,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

/// Selectable service card that reflects `.service-card` and `.selected` styles.
class SelectableCard extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  const SelectableCard({super.key, required this.child, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected ? AppColors.primary : Theme.of(context).dividerColor;
    final List<BoxShadow> shadow = selected ? <BoxShadow>[BoxShadow(color: AppColors.primary.withValues(alpha:0.08), blurRadius: 0, spreadRadius: 2)] : AppShadows.small;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.medium,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.medium,
          border: Border.all(color: borderColor),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );
  }
}


