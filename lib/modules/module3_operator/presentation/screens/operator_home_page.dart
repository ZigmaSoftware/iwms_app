import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';

import 'package:iwms_citizen_app/router/app_router.dart';
import 'operator_qr_scanner.dart';

const Color _operatorPrimary = Color(0xFF1B5E20);
const Color _operatorAccent = Color(0xFF66BB6A);

class OperatorHomePage extends StatefulWidget {
  const OperatorHomePage({super.key});

  @override
  State<OperatorHomePage> createState() => _OperatorHomePageState();
}

class _OperatorHomePageState extends State<OperatorHomePage> {
  _OperatorTab _activeTab = _OperatorTab.scan;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F1),
      body: SafeArea(
        child: Column(
          children: [
            _OperatorHeader(
              greeting: _greeting,
              onLogoutTapped: _showLogoutConfirmation,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<_OperatorTab>(_activeTab),
                  child: _buildTab(_activeTab),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: MotionTabBar(
          labels: const ['Scan', 'Overview', 'Activity'],
          icons: const [
            Icons.qr_code_scanner_rounded,
            Icons.dashboard_customize_rounded,
            Icons.fact_check_outlined,
          ],
          initialSelectedTab: _tabLabel(_activeTab),
          tabBarColor: Colors.white,
          tabSelectedColor: _operatorPrimary,
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

  Widget _buildTab(_OperatorTab tab) {
    switch (tab) {
      case _OperatorTab.scan:
        return _ScanPage(onScan: _openScanner);
      case _OperatorTab.overview:
        return _OverviewPage(onScan: _openScanner);
      case _OperatorTab.activity:
        return const _ActivityPage();
    }
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OperatorQRScanner()),
    );
  }

  void _showLogoutConfirmation() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _operatorPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: _operatorPrimary, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign out of operator console?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You will need to log in again to resume scanning and weighment tasks.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).maybePop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.black.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Stay Logged In'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).maybePop();
                        if (!mounted) return;
                        context.go(AppRoutePaths.operatorLogin);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _operatorPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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

class _OperatorHeader extends StatelessWidget {
  const _OperatorHeader({
    required this.greeting,
    required this.onLogoutTapped,
  });

  final String greeting;
  final VoidCallback onLogoutTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_operatorPrimary, _operatorAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
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
                    greeting,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Operator Console',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Logout',
                onPressed: onLogoutTapped,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  title: 'Today',
                  subtitle: dateLabel,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderStat(
                  title: 'Route status',
                  subtitle: '11 / 18 sites done',
                  icon: Icons.route_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _MetricCard(
        title: 'Stops today',
        value: '18',
        subtitle: '5 pending',
        icon: Icons.maps_home_work_outlined,
      ),
      const _MetricCard(
        title: 'Avg. weight',
        value: '612 kg',
        subtitle: 'per stop',
        icon: Icons.scale_outlined,
      ),
      const _MetricCard(
        title: 'Issues',
        value: '02',
        subtitle: 'Need follow-up',
        icon: Icons.report_problem_outlined,
      ),
    ];

    final quickActions = [
      _QuickAction(
        label: 'Start QR Scan',
        icon: Icons.qr_code_2_rounded,
        onTap: onScan,
      ),
      _QuickAction(
        label: 'Sync Weighments',
        icon: Icons.sync_outlined,
        onTap: () => _showPlaceholder(context, 'Data synced successfully'),
      ),
      _QuickAction(
        label: 'View Assignments',
        icon: Icons.assignment_turned_in_outlined,
        onTap: () => _showPlaceholder(context, 'Assignments refreshed'),
      ),
    ];

    final clusters = [
      const _RouteCard(
        title: 'Gamma - Sector 12',
        address: '12 stops • 4.8 km radius',
        eta: 'Next pickup in 18 min',
      ),
      const _RouteCard(
        title: 'Old Town belt',
        address: '6 stops • high priority',
        eta: 'Inspection at 04:10 PM',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = 14;
              final double maxWidth = constraints.maxWidth;
              double cardWidth;
              if (maxWidth <= 0) {
                cardWidth = maxWidth;
              } else if (maxWidth < 360) {
                cardWidth = maxWidth;
              } else {
                cardWidth = (maxWidth - spacing) / 2;
              }
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: cardWidth,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickActions
                .map((action) => _QuickActionCard(action: action))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Assigned Clusters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...clusters,
        ],
      ),
    );
  }

  static void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ScanPage extends StatelessWidget {
  const _ScanPage({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        double minHeight =
            availableHeight.isFinite ? availableHeight - 56 : 0;
        if (minHeight < 0) minHeight = 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scan household QR code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Stand 1-2 ft away, align the code and tap to capture.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.black.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: onScan,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_operatorPrimary, _operatorAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _operatorPrimary.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 96,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _operatorPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent weighments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._recentWeighments.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WeighmentTile(weighment: item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._timeline.map((item) => _TimelineEntry(item: item)),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    height: 1.2,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _operatorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _operatorPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _operatorPrimary,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _operatorPrimary.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _operatorAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: _operatorPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              action.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.address,
    required this.eta,
  });

  final String title;
  final String address;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _operatorPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route_outlined, color: _operatorPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  eta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _operatorPrimary,
                        fontWeight: FontWeight.w700,
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

class _WeighmentTile extends StatelessWidget {
  const _WeighmentTile({required this.weighment});

  final _Weighment weighment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _operatorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_outlined, color: _operatorPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weighment.customer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  weighment.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            weighment.weight,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _operatorPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _operatorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: _operatorPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.6),
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

class _TimelineItem {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String description;
  final String time;
}

class _Weighment {
  const _Weighment({
    required this.customer,
    required this.weight,
    required this.time,
  });

  final String customer;
  final String weight;
  final String time;
}

const List<_TimelineItem> _timeline = [
  _TimelineItem(
    icon: Icons.check_circle_outline,
    title: 'Weighment synced',
    description: 'Wet waste recorded for Gamma Street 5',
    time: '12:42 PM',
  ),
  _TimelineItem(
    icon: Icons.report_gmailerrorred_outlined,
    title: 'Photo required',
    description: 'Upload proof for skipped pickup #214',
    time: '11:30 AM',
  ),
  _TimelineItem(
    icon: Icons.map_outlined,
    title: 'Route update',
    description: 'New checkpoint assigned near Alpha block',
    time: '10:15 AM',
  ),
];

const List<_Weighment> _recentWeighments = [
  _Weighment(
    customer: 'Gamma Residency - Tower B',
    weight: '428 kg',
    time: '12:32 PM',
  ),
  _Weighment(
    customer: 'Park View Villas',
    weight: '318 kg',
    time: '12:05 PM',
  ),
  _Weighment(
    customer: 'Sector 64 Market',
    weight: '256 kg',
    time: '11:44 AM',
  ),
];

enum _OperatorTab { scan, overview, activity }

const List<_OperatorTab> _operatorTabOrder = [
  _OperatorTab.scan,
  _OperatorTab.overview,
  _OperatorTab.activity,
];

String _tabLabel(_OperatorTab tab) {
  switch (tab) {
    case _OperatorTab.scan:
      return 'Scan';
    case _OperatorTab.overview:
      return 'Overview';
    case _OperatorTab.activity:
      return 'Activity';
  }
}

_OperatorTab? _tabFromLabel(String label) {
  switch (label) {
    case 'Scan':
      return _OperatorTab.scan;
    case 'Overview':
      return _OperatorTab.overview;
    case 'Activity':
      return _OperatorTab.activity;
    default:
      return null;
  }
}

_OperatorTab? _tabFromIndex(int index) {
  if (index >= 0 && index < _operatorTabOrder.length) {
    return _operatorTabOrder[index];
  }
  return null;
}

