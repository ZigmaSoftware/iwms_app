import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_event.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/map.dart';
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
          labels: const ['Dashboard', 'Live Map', 'Vehicles'],
          icons: const [
            Icons.dashboard_customize_outlined,
            Icons.map_outlined,
            Icons.local_shipping_outlined,
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
        return _DashboardTab(onLogout: () => _logout(context));
      case _AdminTab.liveMap:
        return const _LiveMapTab();
      case _AdminTab.vehicles:
        return const _VehiclesTab();
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
      case _AdminTab.liveMap:
        return 'Live Map';
      case _AdminTab.vehicles:
        return 'Vehicles';
    }
  }

  _AdminTab _tabFromLabel(String label) {
    switch (label) {
      case 'Dashboard':
        return _AdminTab.dashboard;
      case 'Live Map':
        return _AdminTab.liveMap;
      case 'Vehicles':
      default:
        return _AdminTab.vehicles;
    }
  }

  _AdminTab _tabFromIndex(int index) {
    if (index == 0) return _AdminTab.dashboard;
    if (index == 1) return _AdminTab.liveMap;
    return _AdminTab.vehicles;
  }
}
// ---------------------------------------------------------------------------
// DASHBOARD TAB
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.onLogout});

  final VoidCallback onLogout;

  List<_WasteSlice> get _wasteSlices => const [
        _WasteSlice('Wet Waste', 52, Color(0xFF00A86B)),
        _WasteSlice('Dry Waste', 35, Color(0xFF4C81FF)),
        _WasteSlice('Mixed Waste', 20, Color(0xFFF4A259)),
      ];

  List<_AttendanceStat> get _attendanceStats => const [
        _AttendanceStat(label: 'Total', count: 182, color: Color(0xFF1B5E20)),
        _AttendanceStat(label: 'Present', count: 158, color: Color(0xFF2E7D32)),
        _AttendanceStat(label: 'Absent', count: 24, color: Color(0xFFD32F2F)),
        _AttendanceStat(label: 'On Leave', count: 12, color: Color(0xFF1976D2)),
      ];

  List<_ActivityEntry> get _recentActivity => const [
        _ActivityEntry('Route completed', 'Driver #45 - 10m ago', ActivityAlert.low),
        _ActivityEntry('Delay reported', 'Supervisor - 25m ago', ActivityAlert.medium),
        _ActivityEntry('Weighbridge entry', 'Operator #12 - 1h ago', ActivityAlert.low),
        _ActivityEntry('Complaint resolved', 'Support Team - 2h ago', ActivityAlert.success),
        _ActivityEntry('Vehicle maintenance', 'Tech #8 - 3h ago', ActivityAlert.medium),
      ];

  List<_WasteCollectionDetail> get _wasteDetails => const [
        _WasteCollectionDetail(zone: 'Central', wet: 26, dry: 18, mixed: 7),
        _WasteCollectionDetail(zone: 'North', wet: 24, dry: 11, mixed: 5),
        _WasteCollectionDetail(zone: 'South', wet: 19, dry: 9, mixed: 4),
        _WasteCollectionDetail(zone: 'East', wet: 21, dry: 13, mixed: 6),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = math.max(constraints.maxWidth - 40, 360);
        final bool multiColumn = contentWidth >= 720;
        final double columnWidth = multiColumn ? (contentWidth - 16) / 2 : contentWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(onLogout: onLogout),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: _DailyWasteCollectionCard(slices: _wasteSlices),
                  ),
                  SizedBox(
                    width: columnWidth,
                    child: _AttendanceMonitorCard(stats: _attendanceStats),
                  ),
                  SizedBox(
                    width: columnWidth,
                    child: _RecentActivityCard(entries: _recentActivity),
                  ),
                  SizedBox(
                    width: contentWidth,
                    child: _WasteCollectionDetailsCard(details: _wasteDetails),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'asset/images/logo.png',
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    'IW',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IWMS Command Center',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor daily operations, vehicles and waste collection.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
class _DailyWasteCollectionCard extends StatelessWidget {
  const _DailyWasteCollectionCard({required this.slices});

  final List<_WasteSlice> slices;

  double get totalTons => slices.fold<double>(0, (sum, item) => sum + item.tons);

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Daily Waste Collection',
      subtitle: 'Live tonnage reported from weighbridge',
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(140),
                  painter: _WasteDonutPainter(slices: slices),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalTons.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'Total tons',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: slices
                  .map(
                    (slice) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slice.label,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          Text(
                            '${slice.tons.toStringAsFixed(0)} tons',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceMonitorCard extends StatelessWidget {
  const _AttendanceMonitorCard({required this.stats});
  final List<_AttendanceStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardSectionCard(
      title: 'Attendance Monitor',
      subtitle: 'Supervisors, drivers and operators',
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats.map((s) => _AttendanceBadge(stat: s)).toList(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Smart reminders enabled for delayed check-ins',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.stat});
  final _AttendanceStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(color: stat.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            stat.count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: stat.color),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.entries});
  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Recent Activity',
      subtitle: 'Latest updates from the ground',
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(entry.icon, color: entry.color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.subtitle,
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WasteCollectionDetailsCard extends StatelessWidget {
  const _WasteCollectionDetailsCard({required this.details});
  final List<_WasteCollectionDetail> details;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        );

    return _DashboardSectionCard(
      title: 'Waste Collection Details',
      subtitle: 'Zone-wise performance for today',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Expanded(child: Center(child: Text('Zone', style: headerStyle))),
                Expanded(child: Center(child: Text('Wet', style: headerStyle))),
                Expanded(child: Center(child: Text('Dry', style: headerStyle))),
                Expanded(child: Center(child: Text('Mixed', style: headerStyle))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.zone,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  Expanded(child: Center(child: Text('${d.wet.toStringAsFixed(1)} t'))),
                  Expanded(child: Center(child: Text('${d.dry.toStringAsFixed(1)} t'))),
                  Expanded(child: Center(child: Text('${d.mixed.toStringAsFixed(1)} t'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// LIVE MAP TAB
// ---------------------------------------------------------------------------

class _LiveMapTab extends StatelessWidget {
  const _LiveMapTab();

  @override
  Widget build(BuildContext context) {
    return const MapScreen(showBackButton: false);
  }
}

// ---------------------------------------------------------------------------
// VEHICLES TAB
// ---------------------------------------------------------------------------

class _VehiclesTab extends StatelessWidget {
  const _VehiclesTab();

  List<_VehicleStatusTile> get _statusTiles => const [
        _VehicleStatusTile(label: 'All Vehicles', count: 12, color: Colors.blueGrey, icon: Icons.directions_bus),
        _VehicleStatusTile(label: 'Running', count: 6, color: Color(0xFF81C784), icon: Icons.speed),
        _VehicleStatusTile(label: 'Idle', count: 3, color: Color(0xFFFFF176), icon: Icons.pause_circle_outline),
        _VehicleStatusTile(label: 'Stopped', count: 3, color: Color(0xFFFF8A80), icon: Icons.stop_circle_outlined),
      ];

  List<_SensorStat> get _sensorStats => const [
        _SensorStat(label: 'Bin Sensors', active: 84, inactive: 16),
        _SensorStat(label: 'Cameras', active: 42, inactive: 5),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = math.max(constraints.maxWidth - 40, 360);
        final bool multiColumn = contentWidth >= 720;
        final double columnWidth = multiColumn ? (contentWidth - 16) / 2 : contentWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fleet Health',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: _DashboardSectionCard(
                      title: 'Vehicle Status',
                      subtitle: 'Select category to drill down',
                      child: Column(
                        children: _statusTiles.map((item) => _VehicleStatusCard(tile: item)).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: columnWidth,
                    child: _WeightmentSummaryCard(
                      trips: 128,
                      totalTons: 642.5,
                      avgTonsPerTrip: 5.02,
                    ),
                  ),
                  SizedBox(
                    width: columnWidth,
                    child: _SensorHealthCard(stats: _sensorStats),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  const _VehicleStatusCard({required this.tile});
  final _VehicleStatusTile tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tile.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(tile.icon, color: tile.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tile.label,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ),
          Text(
            tile.count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: tile.color),
          ),
        ],
      ),
    );
  }
}

class _WeightmentSummaryCard extends StatelessWidget {
  const _WeightmentSummaryCard({
    required this.trips,
    required this.totalTons,
    required this.avgTonsPerTrip,
  });

  final int trips;
  final double totalTons;
  final double avgTonsPerTrip;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Weightment Summary',
      subtitle: 'Last 24 hours',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryStat(label: 'Trips', value: '$trips'),
          _SummaryStat(label: 'Total (tons)', value: totalTons.toStringAsFixed(1)),
          _SummaryStat(label: 'Avg Tons/Trip', value: avgTonsPerTrip.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SensorHealthCard extends StatelessWidget {
  const _SensorHealthCard({required this.stats});
  final List<_SensorStat> stats;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Asset Sensors',
      subtitle: 'Field telemetry status',
      child: Column(
        children: stats
            .map(
              (s) => Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _SensorChip(label: 'Active', value: s.active, color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    _SensorChip(label: 'Inactive', value: s.inactive, color: const Color(0xFFD32F2F)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  const _SensorChip({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// DATA CLASSES
// ---------------------------------------------------------------------------

class _WasteSlice {
  const _WasteSlice(this.label, this.tons, this.color);
  final String label;
  final double tons;
  final Color color;
}

class _WasteDonutPainter extends CustomPainter {
  _WasteDonutPainter({required this.slices});
  final List<_WasteSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.tons);
    if (total == 0) return;

    final strokeWidth = 22.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.tons / total) * 2 * math.pi;
      paint.color = slice.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _WasteDonutPainter oldDelegate) => oldDelegate.slices != slices;
}

class _AttendanceStat {
  const _AttendanceStat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;
}

enum ActivityAlert { low, medium, success }

class _ActivityEntry {
  const _ActivityEntry(this.title, this.subtitle, this.alert);
  final String title;
  final String subtitle;
  final ActivityAlert alert;

  Color get color {
    switch (alert) {
      case ActivityAlert.low:
        return const Color(0xFF26A69A);
      case ActivityAlert.medium:
        return const Color(0xFFF9A825);
      case ActivityAlert.success:
        return const Color(0xFF66BB6A);
    }
  }

  IconData get icon {
    switch (alert) {
      case ActivityAlert.low:
        return Icons.check_circle_outline;
      case ActivityAlert.medium:
        return Icons.warning_amber_rounded;
      case ActivityAlert.success:
        return Icons.verified_rounded;
    }
  }
}

class _WasteCollectionDetail {
  const _WasteCollectionDetail({required this.zone, required this.wet, required this.dry, required this.mixed});
  final String zone;
  final double wet;
  final double dry;
  final double mixed;
}

class _VehicleStatusTile {
  const _VehicleStatusTile({required this.label, required this.count, required this.color, required this.icon});
  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _SensorStat {
  const _SensorStat({required this.label, required this.active, required this.inactive});
  final String label;
  final int active;
  final int inactive;
}

enum _AdminTab { dashboard, liveMap, vehicles }
