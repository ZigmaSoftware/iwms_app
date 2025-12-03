import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_dashboard_models.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/theme/operator_theme.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_cards.dart';

class OperatorProfileScreen extends StatelessWidget {
  const OperatorProfileScreen({
    super.key,
    required this.operatorName,
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
      color: OperatorTheme.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: OperatorTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              name: operatorName,
              code: operatorCode,
              wardLabel: wardLabel,
              zoneLabel: zoneLabel,
              onEdit: onEditProfile,
            ),
            const SizedBox(height: 24),
            OperatorInfoCard(
              title: "Contact details",
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
                    value: contactInfo.designation,
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
              subtitle: "Quick snapshot from attendance module",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OperatorQuickStat(
                          label: "This month",
                          value: attendanceSummary.monthStat,
                          icon: Icons.calendar_month,
                          emphasis: true,
                        ),
                      ),
                      Expanded(
                        child: OperatorQuickStat(
                          label: "Leaves left",
                          value: attendanceSummary.leaveBalance,
                          icon: Icons.eco_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: OperatorTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attendanceSummary.streakLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: OperatorTheme.mutedText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                attendanceSummary.streakValue,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: OperatorTheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              onEditProfile ?? () => _showComingSoon(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: OperatorTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.code,
    required this.wardLabel,
    required this.zoneLabel,
    this.onEdit,
  });

  final String name;
  final String code;
  final String wardLabel;
  final String zoneLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: OperatorTheme.headerGradient,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$wardLabel · $zoneLabel',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit ?? () => _showComingSoon(context),
                icon: const Icon(Icons.settings, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit profile available soon.')));
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
        Icon(icon, color: OperatorTheme.primary),
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
                    ?.copyWith(color: OperatorTheme.mutedText),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: OperatorTheme.strongText,
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
