import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_dashboard_models.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/theme/operator_theme.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_cards.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_header.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_qr_button.dart';
import 'package:iwms_citizen_app/core/theme/app_text_styles.dart';

class OperatorHomeScreen extends StatelessWidget {
  const OperatorHomeScreen({
    super.key,
    required this.operatorName,
    required this.operatorCode,
    required this.wardLabel,
    required this.zoneLabel,
    required this.onScanPressed,
    required this.onLogout,
    this.onOpenAttendance,
    this.onOpenProfile,
    this.nextStop,
    this.lastCollection,
    this.attendanceSummary,
  });

  final String operatorName;
  final String operatorCode;
  final String wardLabel;
  final String zoneLabel;
  final VoidCallback onScanPressed;
  final VoidCallback onLogout;
  final VoidCallback? onOpenAttendance;
  final VoidCallback? onOpenProfile;
  final OperatorNextStop? nextStop;
  final OperatorCollectionSummary? lastCollection;
  final OperatorAttendanceSummary? attendanceSummary;

  @override
  Widget build(BuildContext context) {
    final resolvedNextStop = nextStop ?? const OperatorNextStop();
    final resolvedLastCollection =
        lastCollection ?? const OperatorCollectionSummary();
    final resolvedAttendance =
        attendanceSummary ?? const OperatorAttendanceSummary();

    return ColoredBox(
      color: OperatorTheme.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OperatorHeader(
              name: operatorName,
              badge: operatorCode,
              ward: wardLabel,
              zone: zoneLabel,
              onLogout: onLogout,
              onMenuTap: onOpenProfile,
              subtitle: '$operatorName · $operatorCode',
            ),
            Padding(
              padding: OperatorTheme.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OperatorInfoCard(
                    title: "Next stop",
                    subtitle: resolvedNextStop.label,
                    trailing: Chip(
                      label: Text(
                        resolvedNextStop.status,
                        style: const TextStyle(
                          color: OperatorTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: OperatorTheme.primary.withOpacity(0.1),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      children: [
                        _InfoRowItem(
                          icon: Icons.timer_outlined,
                          title: "ETA",
                          value: resolvedNextStop.timeRemaining,
                          expand: false,
                        ),
                        const SizedBox(width: 16),
                        _InfoRowItem(
                          icon: Icons.location_pin,
                          title: "Route",
                          value: resolvedNextStop.routeName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: OperatorQRButton(onTap: onScanPressed),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Tap to scan QR / Collect waste",
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: OperatorTheme.mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OperatorInfoCard(
                    title: "Last collected",
                    subtitle: resolvedLastCollection.collectedAt,
                    trailing: CircleAvatar(
                      backgroundColor: OperatorTheme.primary.withOpacity(0.12),
                      child: const Icon(Icons.check_rounded,
                          color: OperatorTheme.primary),
                    ),
                    child: Row(
                      children: [
                        _InfoRowItem(
                          icon: Icons.recycling_rounded,
                          title: "Wet",
                          value:
                              '${resolvedLastCollection.wetKg.toStringAsFixed(1)} kg',
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: Colors.black.withOpacity(0.05),
                        ),
                        _InfoRowItem(
                          icon: Icons.layers_rounded,
                          title: "Dry",
                          value:
                              '${resolvedLastCollection.dryKg.toStringAsFixed(1)} kg',
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: Colors.black.withOpacity(0.05),
                        ),
                        _InfoRowItem(
                          icon: Icons.access_time,
                          title: "Time",
                          value: resolvedLastCollection.timeTaken,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AttendanceSection(
                    summary: resolvedAttendance,
                    onTap: onOpenAttendance,
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

class _InfoRowItem extends StatelessWidget {
  const _InfoRowItem({
    required this.icon,
    required this.title,
    required this.value,
    this.expand = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: OperatorTheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: OperatorTheme.mutedText,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OperatorTheme.strongText,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (expand) {
      return Expanded(child: content);
    }
    return Flexible(fit: FlexFit.loose, child: content);
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.summary,
    this.onTap,
  });

  final OperatorAttendanceSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OperatorInfoCard(
      title: "Attendance",
      subtitle: "Stay in sync with your shift",
      trailing: IconButton(
        tooltip: "Open attendance",
        onPressed: onTap,
        icon: const Icon(
          Icons.open_in_new_rounded,
          color: OperatorTheme.primary,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OperatorQuickStat(
                  label: "Today",
                  value: summary.todayStatus,
                  icon: Icons.check_circle_outline,
                  emphasis: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OperatorQuickStat(
                  label: "This month",
                  value: summary.monthStat,
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OperatorQuickStat(
                  label: "Leave balance",
                  value: summary.leaveBalance,
                  icon: Icons.local_florist_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: OperatorTheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.streakLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: OperatorTheme.mutedText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.streakValue,
                        style: AppTextStyles.heading2.copyWith(
                          color: OperatorTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OperatorTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.event_available, color: Colors.white),
                  label: Text(
                    "Mark Attendance",
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
