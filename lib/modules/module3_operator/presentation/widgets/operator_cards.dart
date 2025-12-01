import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/theme/operator_theme.dart';

class OperatorInfoCard extends StatelessWidget {
  const OperatorInfoCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: OperatorTheme.cardRadius,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? OperatorTheme.surface,
          borderRadius: OperatorTheme.cardRadius,
          boxShadow: OperatorTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: OperatorTheme.strongText,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: OperatorTheme.mutedText,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class OperatorQuickStat extends StatelessWidget {
  const OperatorQuickStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Icon(
            icon,
            color: OperatorTheme.primary,
            size: 20,
          ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: emphasis ? FontWeight.w700 : FontWeight.w600,
            color: emphasis ? OperatorTheme.primary : OperatorTheme.strongText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: OperatorTheme.mutedText),
        ),
      ],
    );
  }
}
