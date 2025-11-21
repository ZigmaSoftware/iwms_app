import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_event.dart';
import 'package:iwms_citizen_app/router/app_router.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  _AdminTab _activeTab = _AdminTab.dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildTabBody(
            context,
            theme,
            accent,
            surface,
            _activeTab,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: MotionTabBar(
          labels: const ['Dashboard', 'Attendance', 'Profile'],
          icons: const [
            Icons.dashboard_customize_outlined,
            Icons.fact_check_outlined,
            Icons.person_outline,
          ],
          initialSelectedTab: _tabLabel(_activeTab),
          tabBarColor: surface,
          tabSelectedColor: accent,
          tabIconColor: Colors.black54,
          tabBarHeight: 64,
          tabSize: 52,
          tabIconSize: 22,
          tabIconSelectedSize: 24,
          onTabItemSelected: (value) {
            final tab = value is String
                ? _tabFromLabel(value)
                : value is int
                    ? _tabFromIndex(value)
                    : null;
            if (tab != null && tab != _activeTab) {
              setState(() => _activeTab = tab);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    ThemeData theme,
    Color accent,
    Color surface,
    _AdminTab tab,
  ) {
    switch (tab) {
      case _AdminTab.dashboard:
        return _DashboardTab(accent: accent, surface: surface);
      case _AdminTab.attendance:
        return const _AttendanceTab();
      case _AdminTab.profile:
        return _ProfileTab(
          accent: accent,
          onLogout: () => _logout(context),
        );
    }
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    context.go(AppRoutePaths.selectUser);
  }

  String _tabLabel(_AdminTab tab) {
    switch (tab) {
      case _AdminTab.dashboard:
        return 'Dashboard';
      case _AdminTab.attendance:
        return 'Attendance';
      case _AdminTab.profile:
        return 'Profile';
    }
  }

  _AdminTab _tabFromLabel(String label) {
    switch (label) {
      case 'Dashboard':
        return _AdminTab.dashboard;
      case 'Attendance':
        return _AdminTab.attendance;
      case 'Profile':
      default:
        return _AdminTab.profile;
    }
  }

  _AdminTab _tabFromIndex(int index) {
    if (index == 0) return _AdminTab.dashboard;
    if (index == 1) return _AdminTab.attendance;
    return _AdminTab.profile;
  }
}

// ---------------------------------------------------------------------------
// DASHBOARD TAB
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.accent,
    required this.surface,
  });

  final Color accent;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cards = <_AdminMetric>[
      _AdminMetric(
        title: 'Attendance',
        value: '92%',
        unit: '',
        color: const Color(0xFF1976D2),
        icon: Icons.verified_user_outlined,
      ),
      _AdminMetric(
        title: 'Waste Collected',
        value: '128.4',
        unit: '',
        color: const Color(0xFF2E7D32),
        icon: Icons.delete_outline,
      ),
      _AdminMetric(
        title: 'Trips',
        value: '142',
        unit: '',
        color: const Color(0xFFF57C00),
        icon: Icons.local_shipping_outlined,
      ),
      _AdminMetric(
        title: 'Exceptions',
        value: '9',
        unit: '',
        color: const Color(0xFFD32F2F),
        icon: Icons.error_outline,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Monitor today’s health at a glance. Tap any card for details.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              return _MetricCard(
                metric: cards[index],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMetric {
  const _AdminMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
  });

  final _AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                metric.icon,
                color: metric.color,
              ),
            ),
            const Spacer(),
            Text(
              metric.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metric.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: metric.color,
                  ),
                ),
                if (metric.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    metric.unit,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ATTENDANCE TAB
// ---------------------------------------------------------------------------

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <_AttendanceEntry>[
      const _AttendanceEntry(
        name: 'Operator • Meera',
        status: _AttendanceStatus.present,
        detail: 'Logged in 08:05',
      ),
      const _AttendanceEntry(
        name: 'Driver • Arjun',
        status: _AttendanceStatus.present,
        detail: 'Trip 3 in progress',
      ),
      const _AttendanceEntry(
        name: 'Driver • Nikhil',
        status: _AttendanceStatus.absent,
        detail: 'No login today',
      ),
      const _AttendanceEntry(
        name: 'Operator • Ravi',
        status: _AttendanceStatus.late,
        detail: 'Expected 09:30',
      ),
    ];

    final counts = _AttendanceCounts(
      present: entries.where((e) => e.status == _AttendanceStatus.present).length,
      absent: entries.where((e) => e.status == _AttendanceStatus.absent).length,
      late: entries.where((e) => e.status == _AttendanceStatus.late).length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Attendance',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AttendancePill(
              label: 'Present',
              value: counts.present,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 8),
            _AttendancePill(
              label: 'Late',
              value: counts.late,
              color: const Color(0xFFF57C00),
            ),
            const SizedBox(width: 8),
            _AttendancePill(
              label: 'Absent',
              value: counts.absent,
              color: const Color(0xFFD32F2F),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...entries.map((e) => _AttendanceTile(entry: e)),
      ],
    );
  }
}

class _AttendanceCounts {
  const _AttendanceCounts({
    required this.present,
    required this.absent,
    required this.late,
  });
  final int present;
  final int absent;
  final int late;
}

enum _AttendanceStatus { present, late, absent }

class _AttendanceEntry {
  const _AttendanceEntry({
    required this.name,
    required this.status,
    required this.detail,
  });
  final String name;
  final _AttendanceStatus status;
  final String detail;
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.entry});
  final _AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;
    switch (entry.status) {
      case _AttendanceStatus.present:
        color = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline;
        break;
      case _AttendanceStatus.late:
        color = const Color(0xFFF57C00);
        icon = Icons.schedule_outlined;
        break;
      case _AttendanceStatus.absent:
        color = const Color(0xFFD32F2F);
        icon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(entry.name),
        subtitle: Text(
          entry.detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _statusLabel(entry.status),
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _statusLabel(_AttendanceStatus status) {
    switch (status) {
      case _AttendanceStatus.present:
        return 'Present';
      case _AttendanceStatus.late:
        return 'Late';
      case _AttendanceStatus.absent:
        return 'Absent';
    }
  }
}

class _AttendancePill extends StatelessWidget {
  const _AttendancePill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROFILE TAB
// ---------------------------------------------------------------------------

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.accent,
    required this.onLogout,
  });
  final Color accent;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Admin Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      child: Icon(Icons.admin_panel_settings, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'admin@iwms.gov',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Support'),
                  subtitle: Text(
                    'Report an issue or request access',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: accent),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  trailing: Icon(Icons.chevron_right, color: accent),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _AdminTab { dashboard, attendance, profile }
