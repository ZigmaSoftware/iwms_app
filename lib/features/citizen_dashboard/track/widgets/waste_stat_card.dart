import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/theme_tokens.dart';

class WasteStatCard extends StatelessWidget {
  const WasteStatCard({
    super.key,
    required this.assetPath,
    required this.label,
    required this.weight,
    required this.accentColor,
    required this.formatter,
    required this.isSelected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final double weight;
  final Color accentColor;
  final NumberFormat formatter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderRadius = BorderRadius.circular(DashboardThemeTokens.radiusXL);
    return SizedBox(
      height: 180,
      child: AnimatedContainer(
        duration: DashboardThemeTokens.animationNormal,
        curve: Curves.fastEaseInToSlowEaseOut,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? accentColor
                : accentColor.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isSelected ? 0.3 : 0.18),
              blurRadius: isSelected ? 26 : 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(assetPath),
                          fit: BoxFit.cover,
                          colorFilter: isSelected
                              ? ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.12),
                                  BlendMode.darken,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardThemeTokens.spacing12,
                      vertical: DashboardThemeTokens.spacing10,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft:
                            Radius.circular(DashboardThemeTokens.radiusXL),
                        bottomRight:
                            Radius.circular(DashboardThemeTokens.radiusXL),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accentColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: DashboardThemeTokens.spacing4),
                        AnimatedSwitcher(
                          duration: DashboardThemeTokens.animationNormal,
                          child: Text(
                            '${formatter.format(weight)} kg',
                            key: ValueKey<String>(
                              '${label}_${weight.toStringAsFixed(2)}',
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
