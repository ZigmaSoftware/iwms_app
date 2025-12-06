import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/core/theme/app_colors.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_dashboard_models.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_header.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_cards.dart';

const EdgeInsets _profilePagePadding =
    EdgeInsets.symmetric(horizontal: 20, vertical: 16);
const Gradient _profileHeaderGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.primaryVariant],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class OperatorProfileScreen extends StatelessWidget {
  const OperatorProfileScreen({
    super.key,
    required this.operatorName,
      required this.emp_id,
    required this.operatorCode,
    required this.wardLabel,
    required this.zoneLabel,
    required this.onLogout,
    this.onEditProfile,
    this.contactInfo = const OperatorContactInfo(),
    this.attendanceSummary = const OperatorAttendanceSummary(),
  });

  final String operatorName;
  final String operatorCode;
    final String emp_id;
  final String wardLabel;
  final String zoneLabel;
  final VoidCallback onLogout;
  final VoidCallback? onEditProfile;
  final OperatorContactInfo contactInfo;
  final OperatorAttendanceSummary attendanceSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OperatorHeader(
              name: operatorName,
              badge: operatorCode,
              ward: wardLabel,
              zone: zoneLabel,
              emp_id:emp_id,
              onLogout: onLogout,
              onMenuTap: onEditProfile,
            ),
            Padding(
              padding: _profilePagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  OperatorInfoCard(
                    title: "Contact details",
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    subtitle: "All key references in one place",
                    child: Column(
                      children: [
                        _ProfileDetailRow(
                          icon: Icons.phone,
                          label: "Phone",
                          value: contactInfo.phone,
                        ),
                        const SizedBox(height: 12),
                        _ProfileDetailRow(
                          icon: Icons.mail_outline,
                          label: "Email",
                          value: contactInfo.email,
                        ),
                        const SizedBox(height: 12),
                        _ProfileDetailRow(
                          icon: Icons.badge_outlined,
                          label: "Designation",
                          value: contactInfo.designation ?? "-",
                        ),
                        const SizedBox(height: 12),
                        _ProfileDetailRow(
                          icon: Icons.location_city,
                          label: "Ward / Zone",
                          value: '$wardLabel · $zoneLabel',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OperatorInfoCard(
                    title: "Attendance & leave",
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    subtitle: "Quick snapshot from attendance module",
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OperatorQuickStat(
                                label: "This month",
                                value: attendanceSummary.monthStat ?? "--",
                                icon: Icons.calendar_month,
                                emphasis: true,
                              ),
                            ),
                            Expanded(
                              child: OperatorQuickStat(
                                label: "Leaves left",
                                value: attendanceSummary.leaveBalance ?? "--",
                                icon: Icons.eco_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attendanceSummary.streakLabel ??
                                          "Attendance streak",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      attendanceSummary.streakValue ?? "--",
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: onEditProfile ??
                                    () => _showComingSoon(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(Icons.edit,
                                    color: Colors.white),
                                label: const Text(
                                  "Edit profile",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFCF1B1B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Edit profile flow will open the existing screen."),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
