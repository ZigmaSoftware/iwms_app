import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_event.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/map.dart'
    as citizen_map;
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
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildTabBody(context, _activeTab),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: MotionTabBar(
          labels: const ['Home', 'Map', 'Vehicles'],
          icons: const [
            Icons.home_outlined,
            Icons.map_outlined,
            Icons.directions_bus_outlined,
          ],
          initialSelectedTab: _tabLabel(_activeTab),
          tabBarColor: surface,
          tabSelectedColor: theme.colorScheme.primary,
          tabIconColor: Colors.black54,
          tabBarHeight: 62,
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

  Widget _buildTabBody(BuildContext context, _AdminTab tab) {
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
        return 'Home';
      case _AdminTab.liveMap:
        return 'Map';
      case _AdminTab.vehicles:
        return 'Vehicles';
    }
  }

  _AdminTab _tabFromLabel(String label) {
    switch (label) {
      case 'Home':
        return _AdminTab.dashboard;
      case 'Map':
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
// DASHBOARD
// ---------------------------------------------------------------------------

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.onLogout});

  final VoidCallback onLogout;

  List<_ActivityEntry> get _recentActivity => const [
        _ActivityEntry(
            'Route completed', 'Driver #45 - 3h ago', ActivityAlert.success),
        _ActivityEntry(
            'Delay reported', 'Supervisor #5 - 3h ago', ActivityAlert.warning),
        _ActivityEntry('Complaint resolved', 'Support Team - 2h ago',
            ActivityAlert.success),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = 20.0;
        final maxWidth = constraints.maxWidth;
        final bool twoColumns = maxWidth >= 700;
        final double columnWidth = twoColumns
            ? (maxWidth - horizontalPadding * 2 - 16) / 2
            : maxWidth - horizontalPadding * 2;

        return SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBanner(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: columnWidth, child: const _DailyWasteCard()),
                  SizedBox(width: columnWidth, child: const _AttendanceCard()),
                  SizedBox(
                      width: columnWidth,
                      child: _ActivityCard(entries: _recentActivity)),
                  SizedBox(
                      width: columnWidth,
                      child: const _VehicleStatusOverview()),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.eco_rounded,
                          color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IWMS',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Command Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track waste, attendance and vehicles with live updates.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Center(
                  child: Icon(Icons.local_shipping_rounded,
                      size: 72, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyWasteCard extends StatelessWidget {
  const _DailyWasteCard();

  static const slices = <_WasteSlice>[
    _WasteSlice('Wet Waste', 52, Color(0xFF2E7D32)),
    _WasteSlice('Dry Waste', 35, Color(0xFF2979FF)),
    _WasteSlice('Mixed Waste', 20, Color(0xFFFFB74D)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.tons);
    return _DashboardSectionCard(
      title: 'Daily Waste Collection',
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
                    painter: _WasteDonutPainter(slices: slices)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toStringAsFixed(0),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text('Total tons',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
                            decoration: BoxDecoration(
                                color: slice.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(slice.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
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

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  static const stats = <_AttendanceStat>[
    _AttendanceStat(label: 'Total', count: 158, color: Color(0xFF1B5E20)),
    _AttendanceStat(label: 'Present', count: 158, color: Color(0xFF4CAF50)),
    _AttendanceStat(label: 'Absent', count: 24, color: Color(0xFFE53935)),
    _AttendanceStat(label: 'On Leave', count: 12, color: Color(0xFF1E88E5)),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Attendance Monitor',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats
            .map(
              (stat) => Container(
                width: 130,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.count.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w800, color: stat.color),
                    ),
                    const SizedBox(height: 2),
                    Text(stat.label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entries});

  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Recent Activity',
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(entry.icon, color: entry.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(entry.subtitle,
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
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

class _VehicleStatusOverview extends StatelessWidget {
  const _VehicleStatusOverview();

  @override
  Widget build(BuildContext context) {
    final status = {
      'Running': _VehicleStatus(count: 6, color: const Color(0xFF66BB6A)),
      'Idle': _VehicleStatus(count: 3, color: const Color(0xFFFFF176)),
      'Stopped': _VehicleStatus(count: 3, color: const Color(0xFFE57373)),
    };
    return _DashboardSectionCard(
      title: 'Vehicle Status',
      child: Column(
        children: status.entries
            .map(
              (entry) => Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: entry.value.color.withOpacity(0.12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: entry.value.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(entry.value.count.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: entry.value.color)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            child,
          ],
        ),
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
    return const citizen_map.MapScreen(showBackButton: false);
  }
}

// ---------------------------------------------------------------------------
// VEHICLES TAB
// ---------------------------------------------------------------------------

class _VehiclesTab extends StatelessWidget {
  const _VehiclesTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = 20.0;
        final width = constraints.maxWidth;
        final bool twoColumns = width >= 700;
        final double columnWidth =
            twoColumns ? (width - padding * 2 - 16) / 2 : width - padding * 2;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Overview',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                      width: columnWidth,
                      child: const _VehicleStatusOverview()),
                  SizedBox(
                    width: columnWidth,
                    child: const _WeightmentSummaryCard(
                        trips: 128, totalTons: 642.5, avgTonsPerTrip: 5.02),
                  ),
                  SizedBox(
                      width: columnWidth, child: const _SensorHealthCard()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeightmentSummaryCard extends StatelessWidget {
  const _WeightmentSummaryCard(
      {required this.trips,
      required this.totalTons,
      required this.avgTonsPerTrip});

  final int trips;
  final double totalTons;
  final double avgTonsPerTrip;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Weightment Summary',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryDatum(label: 'Trips', value: '$trips'),
          _SummaryDatum(
              label: 'Total (tons)', value: totalTons.toStringAsFixed(1)),
          _SummaryDatum(
              label: 'Avg tons/trip', value: avgTonsPerTrip.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _SummaryDatum extends StatelessWidget {
  const _SummaryDatum({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SensorHealthCard extends StatelessWidget {
  const _SensorHealthCard();

  static const stats = <_SensorStat>[
    _SensorStat(label: 'Bin Sensors', active: 84, inactive: 16),
    _SensorStat(label: 'Cameras', active: 42, inactive: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Asset Sensors',
      child: Column(
        children: stats
            .map(
              (stat) => Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _SensorChip(
                        label: 'Active',
                        value: stat.active,
                        color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    _SensorChip(
                        label: 'Inactive',
                        value: stat.inactive,
                        color: const Color(0xFFE53935)),
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
  const _SensorChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
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
  const _WasteDonutPainter({required this.slices});
  final List<_WasteSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.tons);
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
          rect.deflate(strokeWidth / 2), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _WasteDonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _AttendanceStat {
  const _AttendanceStat(
      {required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;
}

enum ActivityAlert { success, warning }

class _ActivityEntry {
  const _ActivityEntry(this.title, this.subtitle, this.alert);
  final String title;
  final String subtitle;
  final ActivityAlert alert;

  Color get color => alert == ActivityAlert.success
      ? const Color(0xFF2E7D32)
      : const Color(0xFFF9A825);
  IconData get icon => alert == ActivityAlert.success
      ? Icons.check_circle_outline
      : Icons.warning_amber_rounded;
}

class _VehicleStatus {
  const _VehicleStatus({required this.count, required this.color});
  final int count;
  final Color color;
}

class _SensorStat {
  const _SensorStat(
      {required this.label, required this.active, required this.inactive});
  final String label;
  final int active;
  final int inactive;
}

enum _AdminTab { dashboard, liveMap, vehicles }
