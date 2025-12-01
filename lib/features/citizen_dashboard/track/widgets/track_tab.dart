import 'package:flutter/material.dart';
import '../../common/theme_tokens.dart';
import '../controllers/track_controller.dart';
import '../models/waste_period.dart';
import '../models/waste_summary.dart';
import '../widgets/waste_stat_card.dart';

enum WasteMetric { total, wet, dry, mixed }

class TrackTab extends StatefulWidget {
  const TrackTab({
    super.key,
    required this.controller,
    required this.highlightColor,
    required this.textColor,
    required this.onPickDate,
  });

  final TrackController controller;
  final Color highlightColor;
  final Color textColor;
  final Future<void> Function() onPickDate;

  @override
  State<TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<TrackTab> {
  WasteMetric _activeMetric = WasteMetric.total;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final summary = controller.currentSummary;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return RefreshIndicator(
      onRefresh: () => controller.refresh(force: true),
      color: widget.highlightColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DashboardThemeTokens.spacing20,
          DashboardThemeTokens.spacing20,
          DashboardThemeTokens.spacing20,
          DashboardThemeTokens.spacing32,
        ),
        children: [
          _buildTrackHeader(theme),
          const SizedBox(height: 16),
          _buildTrackSummarySection(theme, summary),
          const SizedBox(height: 20),
          Text(
            'Data refreshed for ${controller.displayFormat.format(controller.selectedDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: screenWidth * 0.032,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHeader(ThemeData theme) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: widget.textColor,
      fontSize: screenWidth * 0.06,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Track Your Waste',
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Live weighment figures from the city for the selected date.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: screenWidth * 0.035,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WastePeriod>(
                    isExpanded: true,
                    value: widget.controller.selectedPeriod,
                    items: WastePeriod.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(_labelForPeriod(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          widget.controller.setPeriod(value);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CalendarChip(
              highlightColor: widget.highlightColor,
              label: widget.controller.shortDisplayFormat
                  .format(widget.controller.selectedDate),
              onTap: widget.onPickDate,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackSummarySection(
    ThemeData theme,
    WasteSummary? summary,
  ) {
    if (widget.controller.loading) {
      return _buildTrackStatusCard(
        message: 'Pulling live collection figures...',
        accentColor: widget.highlightColor,
        showLoading: true,
      );
    }

    if (widget.controller.error != null) {
      return _buildTrackStatusCard(
        message: widget.controller.error!,
        accentColor: widget.highlightColor,
        actionLabel: 'Retry now',
        onAction: () => widget.controller.refresh(force: true),
      );
    }

    if (summary == null) {
      return _buildTrackStatusCard(
        message: 'No collection data is available for this date yet.',
        accentColor: widget.highlightColor,
        actionLabel: 'Choose another date',
        onAction: widget.onPickDate,
      );
    }

    final cards = <({
      String asset,
      String label,
      double weight,
      Color color,
      WasteMetric metric,
    })>[
      (
        asset: 'assets/cards/wetwaste.png',
        label: 'Wet Waste',
        weight: summary.wetWeight,
        color: const Color(0xFF1976D2),
        metric: WasteMetric.wet
      ),
      (
        asset: 'assets/cards/drywaste.png',
        label: 'Dry Waste',
        weight: summary.dryWeight,
        color: const Color(0xFF2E7D32),
        metric: WasteMetric.dry
      ),
      (
        asset: 'assets/cards/mixedwaste.png',
        label: 'Mixed Waste',
        weight: summary.mixWeight,
        color: const Color(0xFFF57F17),
        metric: WasteMetric.mixed
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSummaryCard(theme, summary),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth;
            final itemWidth = available > 0 ? (available - 24) / 3 : available;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: itemWidth,
                      child: WasteStatCard(
                        assetPath: card.asset,
                        label: card.label,
                        weight: card.weight,
                        accentColor: card.color,
                        formatter: widget.controller.weightFormatter,
                        isSelected: _activeMetric == card.metric,
                        onTap: () => _toggleMetric(card.metric),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildMetricDetailCard(theme, summary),
        const SizedBox(height: 16),
        _buildTrendSection(theme),
      ],
    );
  }

  Widget _buildHeroSummaryCard(ThemeData theme, WasteSummary summary) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontal = screenWidth * 0.05;
    return AnimatedContainer(
      duration: DashboardThemeTokens.animationSlow,
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.highlightColor.withValues(alpha: 0.96),
            widget.highlightColor.withValues(alpha: 0.68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DashboardThemeTokens.radiusXL),
        boxShadow: [
          BoxShadow(
            color: widget.highlightColor.withValues(alpha: 0.32),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total trips',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: DashboardThemeTokens.spacing6),
                  Text(
                    summary.totalTrip.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg per trip',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: DashboardThemeTokens.spacing6),
                  Text(
                    '${widget.controller.averageFormatter.format(summary.averageWeightPerTrip)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DashboardThemeTokens.spacing20),
          Text(
            'Total weight',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: DashboardThemeTokens.spacing6),
          Text(
            '${widget.controller.weightFormatter.format(summary.totalNetWeight)} kg',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DashboardThemeTokens.spacing8),
          Text(
            'Live data for ${widget.controller.displayFormat.format(summary.date)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDetailCard(
    ThemeData theme,
    WasteSummary summary,
  ) {
    final metric = _activeMetric;
    final double weight = _metricWeight(summary, metric);
    final Color accent = _metricAccent(metric);
    final String weightLabel = '${widget.controller.weightFormatter.format(weight)} kg';

    return AnimatedContainer(
      duration: DashboardThemeTokens.animationSlow,
      curve: Curves.fastEaseInToSlowEaseOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DashboardThemeTokens.radiusXL),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: DashboardThemeTokens.animationNormal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Text(
              _metricHeader(metric),
              key: ValueKey<String>('metric-header-${metric.name}'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: DashboardThemeTokens.spacing6),
          AnimatedSwitcher(
            duration: DashboardThemeTokens.animationSlow,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInBack,
            child: Text(
              weightLabel,
              key: ValueKey<String>('metric-weight-$weightLabel'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: widget.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: DashboardThemeTokens.spacing8),
          Text(
            metric == WasteMetric.total
                ? 'Tap a card above to view detailed breakdown.'
                : 'Tap again to switch back to total waste.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStatusCard({
    required String message,
    required Color accentColor,
    bool showLoading = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          DashboardThemeTokens.lightShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLoading)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: DashboardThemeTokens.spacing12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (actionLabel != null && onAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleMetric(WasteMetric metric) {
    setState(() {
      _activeMetric = _activeMetric == metric ? WasteMetric.total : metric;
    });
  }

  double _metricWeight(WasteSummary summary, WasteMetric metric) {
    switch (metric) {
      case WasteMetric.wet:
        return summary.wetWeight;
      case WasteMetric.dry:
        return summary.dryWeight;
      case WasteMetric.mixed:
        return summary.mixWeight;
      case WasteMetric.total:
        return summary.totalNetWeight;
    }
  }

  Color _metricAccent(WasteMetric metric) {
    switch (metric) {
      case WasteMetric.wet:
        return const Color(0xFF1976D2);
      case WasteMetric.dry:
        return const Color(0xFF2E7D32);
      case WasteMetric.mixed:
        return const Color(0xFFF57F17);
      case WasteMetric.total:
        return widget.highlightColor;
    }
  }

  String _metricHeader(WasteMetric metric) {
    switch (metric) {
      case WasteMetric.wet:
        return 'Wet waste collected';
      case WasteMetric.dry:
        return 'Dry waste collected';
      case WasteMetric.mixed:
        return 'Mixed waste collected';
      case WasteMetric.total:
        return 'Total waste collected';
    }
  }

  String _labelForPeriod(WastePeriod period) {
    switch (period) {
      case WastePeriod.daily:
        return 'Daily';
      case WastePeriod.monthly:
        return 'Monthly';
      case WastePeriod.yearly:
        return 'Yearly';
    }
  }

  Widget _buildTrendSection(ThemeData theme) {
    // Trend chart removed per request.
    return const SizedBox.shrink();
  }
}

class _CalendarChip extends StatelessWidget {
  const _CalendarChip({
    required this.highlightColor,
    required this.label,
    required this.onTap,
  });
  final Color highlightColor;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardThemeTokens.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DashboardThemeTokens.spacing12,
            vertical: DashboardThemeTokens.spacing10,
          ),
          decoration: BoxDecoration(
            color: highlightColor.withValues(alpha: 0.15),
            borderRadius:
                BorderRadius.circular(DashboardThemeTokens.radiusLarge),
            border: Border.all(color: highlightColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 20, color: highlightColor),
              const SizedBox(width: DashboardThemeTokens.spacing8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: highlightColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: highlightColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
