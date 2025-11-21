import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:iwms_citizen_app/core/di.dart';
import 'package:iwms_citizen_app/data/models/vehicle_model.dart';
import 'package:iwms_citizen_app/data/repositories/vehicle_repository.dart';
import 'package:iwms_citizen_app/features/citizen_dashboard/track/models/waste_summary.dart';
import 'package:iwms_citizen_app/features/citizen_dashboard/track/services/track_service.dart';

const _primaryGreen = Color(0xFF2E7D32);
const _softGreen = Color(0xFFA5D6A7);
const _softYellow = Color(0xFFFFE082);
const _softRed = Color(0xFFFF8A80);
const _softBlue = Color(0xFFBBDEFB);
const _bgWhite = Color(0xFFFFFFFF);
const _cardBackground = Color(0xFFF8F9FB);
const _iconGray = Color(0xFF9E9E9E);
const _borderGray = Color(0xFFE0E0E0);

List<BoxShadow> _softCardShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];

BoxDecoration _cardDecoration({Color color = _cardBackground}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      boxShadow: _softCardShadow(),
    );

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardShell();
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell();

  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> {
  late final TrackService _trackService;
  late final VehicleRepository _vehicleRepository;
  late Future<_DashboardData> _dashboardFuture;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _trackService = TrackService();
    _vehicleRepository = getIt<VehicleRepository>();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_DashboardData> _loadDashboardData() async {
    final today = DateTime.now();
    final summaryMap = await _trackService.fetchMonthlySummaries(today);
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    WasteSummary? summary;
    if (summaryMap.containsKey(todayKey)) {
      summary = summaryMap[todayKey];
    } else if (summaryMap.isNotEmpty) {
      summary = summaryMap.values.first;
    }

    final vehicles = await _vehicleRepository.fetchAllVehicleLocations();
    return _DashboardData(summary: summary, vehicles: vehicles);
  }

  Future<void> _refreshHome() async {
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHome(context),
          MapScreen(vehicleRepository: _vehicleRepository),
          VehiclesScreen(vehicleRepository: _vehicleRepository),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: _DashboardNavBar(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 52, color: _iconGray),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load live data.\nPull down to retry.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshHome,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data ?? const _DashboardData.empty();
        return SafeArea(
          top: true,
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = _DashboardHomeContent(
                  data: data,
                  maxWidth: constraints.maxWidth,
                );
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: content,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent({required this.data, required this.maxWidth});

  final _DashboardData data;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final wasteSlices = [
      _WasteSlice('Wet Waste', summary?.wetWeight ?? 0, _primaryGreen),
      _WasteSlice('Dry Waste', summary?.dryWeight ?? 0, const Color(0xFF2979FF)),
      _WasteSlice('Mixed Waste', summary?.mixWeight ?? 0, const Color(0xFFFFB74D)),
    ];
    final statusCounts = data.statusCounts;

    return Column(
      children: [
        _HeaderHero(maxWidth: maxWidth),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _bgWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _softCardShadow(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Column(
                children: [
                  _DailyWasteCard(summary: summary, slices: wasteSlices),
                  const SizedBox(height: 16),
                  _AttendanceRow(
                    statusCounts: statusCounts,
                    totalVehicles: data.vehicles.length,
                  ),
                  const SizedBox(height: 16),
                  _ActivityAndVehicleRow(
                    vehicles: data.vehicles,
                    statusCounts: statusCounts,
                    summary: summary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderHero extends StatelessWidget {
  const _HeaderHero({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDFF3DD), Color(0xFFFFFFFF)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: _softCardShadow(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'asset/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: _primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'IWMS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: math.min(140, maxWidth * 0.35),
            child: Image.asset(
              'asset/images/vehicle.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_shipping,
                size: 72,
                color: _primaryGreen,
              ),
            ),
          )
        ],
      ),
    );
  }
}
class _DailyWasteCard extends StatelessWidget {
  const _DailyWasteCard({required this.summary, required this.slices});

  final WasteSummary? summary;
  final List<_WasteSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    final subtitle = summary != null
        ? DateFormat('EEE, d MMM').format(summary!.date)
        : 'Live collection (today)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Waste Collection',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: _iconGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew, size: 16, color: _primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              final chart = SizedBox(
                height: 140,
                width: 140,
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
                          total.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total tons',
                          style: TextStyle(fontSize: 12, color: _iconGray),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              final legend = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: slice.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slice.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${slice.value.toStringAsFixed(1)} t',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              );

              return isNarrow
                  ? Column(children: [chart, const SizedBox(height: 14), legend])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [chart, const SizedBox(width: 16), legend],
                    );
            },
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Text(
              'Average per trip: ${summary!.averageWeightPerTrip.toStringAsFixed(2)} tons across ${summary!.totalTrip} trips',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _iconGray),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.statusCounts,
    required this.totalVehicles,
  });

  final Map<_VehicleState, int> statusCounts;
  final int totalVehicles;

  @override
  Widget build(BuildContext context) {
    final running = statusCounts[_VehicleState.running] ?? 0;
    final idle = statusCounts[_VehicleState.idle] ?? 0;
    final present = running + idle;
    final onLeave = statusCounts[_VehicleState.parked] ?? 0;
    final absent = statusCounts[_VehicleState.nodata] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _AttendanceTile(
            label: 'Total',
            count: totalVehicles,
            background: const Color(0xFFE8F5E9),
            textColor: _primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AttendanceTile(
            label: 'Present',
            count: present,
            background: const Color(0xFFFFEBEE),
            textColor: const Color(0xFFB71C1C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AttendanceTile(
            label: 'Absent',
            count: absent,
            background: const Color(0xFFFFF3E0),
            textColor: const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AttendanceTile(
            label: 'On Leave',
            count: onLeave,
            background: const Color(0xFFE3F2FD),
            textColor: const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.label,
    required this.count,
    required this.background,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActivityAndVehicleRow extends StatelessWidget {
  const _ActivityAndVehicleRow({
    required this.vehicles,
    required this.statusCounts,
    required this.summary,
  });

  final List<VehicleModel> vehicles;
  final Map<_VehicleState, int> statusCounts;
  final WasteSummary? summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final recent = _RecentActivityCard(
          entries: _buildActivityEntries(vehicles, summary, statusCounts),
        );
        final vehicleStatus = _VehicleStatusCard(
          vehicles: vehicles,
          statusCounts: statusCounts,
        );
        if (stacked) {
          return Column(
            children: [
              recent,
              const SizedBox(height: 12),
              vehicleStatus,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: recent),
            const SizedBox(width: 12),
            Expanded(child: vehicleStatus),
          ],
        );
      },
    );
  }

  List<_ActivityEntry> _buildActivityEntries(
    List<VehicleModel> vehicles,
    WasteSummary? summary,
    Map<_VehicleState, int> statusCounts,
  ) {
    final running = statusCounts[_VehicleState.running] ?? 0;
    final idle = statusCounts[_VehicleState.idle] ?? 0;
    final latest = vehicles.isNotEmpty ? vehicles.first : null;
    final lastUpdate = latest?.lastUpdated;

    return [
      if (summary != null)
        _ActivityEntry(
          'Waste collected ${summary.totalNetWeight.toStringAsFixed(1)} t',
          'Average ${summary.averageWeightPerTrip.toStringAsFixed(2)} t per trip',
          ActivityTone.success,
        ),
      _ActivityEntry(
        'Active vehicles: ${running + idle}',
        'Running: $running | Idle: $idle',
        ActivityTone.success,
      ),
      _ActivityEntry(
        'Latest update',
        lastUpdate != null ? 'Last seen ${_formatRelative(lastUpdate)}' : 'Awaiting telemetry',
        lastUpdate != null ? ActivityTone.success : ActivityTone.warning,
      ),
    ];
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.entries});

  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(entry.icon, color: entry.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          entry.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _iconGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  const _VehicleStatusCard({
    required this.vehicles,
    required this.statusCounts,
  });

  final List<VehicleModel> vehicles;
  final Map<_VehicleState, int> statusCounts;

  @override
  Widget build(BuildContext context) {
    final cards = <_StatusCount>[
      _StatusCount(
          label: 'Running',
          value: statusCounts[_VehicleState.running] ?? 0,
          color: _primaryGreen),
      _StatusCount(
          label: 'Idle',
          value: statusCounts[_VehicleState.idle] ?? 0,
          color: _softYellow),
      _StatusCount(
          label: 'Stopped',
          value: statusCounts[_VehicleState.parked] ?? 0,
          color: _softRed),
      _StatusCount(
          label: 'No Data',
          value: statusCounts[_VehicleState.nodata] ?? 0,
          color: _iconGray),
    ];

    final highlighted =
        vehicles.isNotEmpty ? vehicles.firstWhere((_) => true) : null;
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Status',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...cards.map(
            (item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    item.value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (highlighted != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _softBlue.withValues(alpha: 0.4),
                  ),
                  child: const Icon(Icons.local_shipping, color: _primaryGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlighted.registrationNumber ??
                            'Vehicle ${highlighted.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        highlighted.address ?? 'Live telemetry',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _iconGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(state: _vehicleStateFor(highlighted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onChanged,
      backgroundColor: Colors.white,
      selectedItemColor: _primaryGreen,
      unselectedItemColor: _iconGray,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          label: 'Vehicles',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}
// ---------------------------------------------------------------------------
// MAP SCREEN
// ---------------------------------------------------------------------------

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.vehicleRepository});

  final VehicleRepository vehicleRepository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<VehicleModel> _vehicles = const [];
  bool _loading = true;
  Object? _error;
  Timer? _poller;
  String _search = '';

  final _countries = const ['India', 'UAE'];
  final _states = const ['Delhi', 'Karnataka', 'Uttar Pradesh'];
  final _cities = const ['Delhi', 'Bangalore', 'Noida'];
  final _zones = const ['Zone 1', 'Zone 2', 'Zone 3'];

  String _selectedCountry = 'India';
  String _selectedState = 'Delhi';
  String _selectedCity = 'Delhi';
  String _selectedZone = 'Zone 1';

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
    _poller =
        Timer.periodic(const Duration(seconds: 25), (_) => _fetchVehicles(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _fetchVehicles({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await widget.vehicleRepository.fetchAllVehicleLocations();
      if (!mounted) return;
      setState(() {
        _vehicles = result;
        _loading = false;
      });
      _fitBounds(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _fitBounds(List<VehicleModel> vehicles) {
    if (vehicles.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(
      vehicles
          .map((v) => LatLng(v.latitude, v.longitude))
          .toList(growable: false),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(36)),
    );
  }

  LatLng get _defaultCenter => _vehicles.isNotEmpty
      ? LatLng(_vehicles.first.latitude, _vehicles.first.longitude)
      : const LatLng(28.6139, 77.2090);

  Map<_VehicleState, int> get _statusCounts =>
      _DashboardData.countByStatus(_vehicles);

  List<VehicleModel> get _filteredVehicles {
    if (_search.isEmpty) return _vehicles;
    final query = _search.toLowerCase();
    return _vehicles
        .where((v) =>
            (v.registrationNumber ?? '').toLowerCase().contains(query) ||
            (v.driverName ?? '').toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchVehicles,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapHeight =
                (constraints.maxHeight * 0.55).clamp(280.0, 520.0).toDouble();
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Live Map',
                    subtitle: 'Realtime coordinates from the tracking API',
                  ),
                  const SizedBox(height: 14),
                  _SearchField(
                    hint: 'Search vehicle or driver',
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: _softCardShadow(),
                          ),
                          height: mapHeight,
                          width: double.infinity,
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : _error != null
                                  ? Center(
                                      child: Text(
                                        'Unable to load map data',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    )
                                  : FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: _defaultCenter,
                                        initialZoom: 12,
                                        maxZoom: 18,
                                        minZoom: 3,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          subdomains: const ['a', 'b', 'c'],
                                          userAgentPackageName:
                                              'com.iwms.app',
                                          retinaMode: true,
                                        ),
                                        MarkerLayer(
                                          markers: _filteredVehicles
                                              .map(
                                                (vehicle) => Marker(
                                                  point: LatLng(vehicle.latitude,
                                                      vehicle.longitude),
                                                  width: 42,
                                                  height: 42,
                                                  child: _VehicleMarker(
                                                    vehicle: vehicle,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          child: IconButton(
                            icon: const Icon(Icons.my_location,
                                color: _primaryGreen),
                            onPressed: () =>
                                _mapController.move(_defaultCenter, 14),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  _RegionFilters(
                    countries: _countries,
                    states: _states,
                    cities: _cities,
                    zones: _zones,
                    selectedCountry: _selectedCountry,
                    selectedState: _selectedState,
                    selectedCity: _selectedCity,
                    selectedZone: _selectedZone,
                    onChanged: (country, state, city, zone) {
                      setState(() {
                        _selectedCountry = country;
                        _selectedState = state;
                        _selectedCity = city;
                        _selectedZone = zone;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _StatusPillsRow(counts: _statusCounts),
                  const SizedBox(height: 12),
                  _VehiclePreviewList(vehicles: _filteredVehicles),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final state = _vehicleStateFor(vehicle);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: _softCardShadow(),
      ),
      child: Center(
        child: Icon(
          Icons.local_shipping,
          size: 22,
          color: _vehicleStateColor(state),
        ),
      ),
    );
  }
}

class _RegionFilters extends StatelessWidget {
  const _RegionFilters({
    required this.countries,
    required this.states,
    required this.cities,
    required this.zones,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedCity,
    required this.selectedZone,
    required this.onChanged,
  });

  final List<String> countries;
  final List<String> states;
  final List<String> cities;
  final List<String> zones;
  final String selectedCountry;
  final String selectedState;
  final String selectedCity;
  final String selectedZone;
  final void Function(String, String, String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTight = constraints.maxWidth < 420;
      final fieldWidth = isTight ? double.infinity : (constraints.maxWidth / 2) - 8;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: fieldWidth,
            child: _RoundedDropdown(
              value: selectedCountry,
              items: countries,
              label: 'Country',
              onChanged: (value) => onChanged(
                value ?? selectedCountry,
                selectedState,
                selectedCity,
                selectedZone,
              ),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: _RoundedDropdown(
              value: selectedState,
              items: states,
              label: 'State',
              onChanged: (value) => onChanged(
                selectedCountry,
                value ?? selectedState,
                selectedCity,
                selectedZone,
              ),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: _RoundedDropdown(
              value: selectedCity,
              items: cities,
              label: 'City',
              onChanged: (value) => onChanged(
                selectedCountry,
                selectedState,
                value ?? selectedCity,
                selectedZone,
              ),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: _RoundedDropdown(
              value: selectedZone,
              items: zones,
              label: 'Zone',
              onChanged: (value) => onChanged(
                selectedCountry,
                selectedState,
                selectedCity,
                value ?? selectedZone,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _RoundedDropdown extends StatelessWidget {
  const _RoundedDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final String label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderGray),
        boxShadow: _softCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _iconGray,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              icon: const Icon(Icons.keyboard_arrow_down),
              borderRadius: BorderRadius.circular(16),
              onChanged: onChanged,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
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

class _StatusPillsRow extends StatelessWidget {
  const _StatusPillsRow({required this.counts});

  final Map<_VehicleState, int> counts;

  @override
  Widget build(BuildContext context) {
    final pills = [
      _StatusPill(state: _VehicleState.running, count: counts[_VehicleState.running] ?? 0),
      _StatusPill(state: _VehicleState.idle, count: counts[_VehicleState.idle] ?? 0),
      _StatusPill(state: _VehicleState.parked, count: counts[_VehicleState.parked] ?? 0),
      _StatusPill(state: _VehicleState.nodata, count: counts[_VehicleState.nodata] ?? 0),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }
}

class _VehiclePreviewList extends StatelessWidget {
  const _VehiclePreviewList({required this.vehicles});

  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(color: _bgWhite),
        child: const Text(
          'No vehicles found for the current filters.',
          style: TextStyle(color: _iconGray),
        ),
      );
    }
    final preview = vehicles.take(3).toList();
    return Column(
      children: preview
          .map(
            (v) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(color: _bgWhite),
              child: Row(
                children: [
                  Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _softBlue.withValues(alpha: 0.4),
            ),
            child:
                const Icon(Icons.directions_bus, color: _primaryGreen),
          ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.registrationNumber ?? 'Vehicle ${v.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          v.driverName ?? 'Driver not assigned',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _iconGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(state: _vehicleStateFor(v)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
// ---------------------------------------------------------------------------
// VEHICLES SCREEN
// ---------------------------------------------------------------------------

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key, required this.vehicleRepository});

  final VehicleRepository vehicleRepository;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<VehicleModel> _vehicles = const [];
  bool _loading = true;
  Object? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
    _poller =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetchVehicles(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _fetchVehicles({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await widget.vehicleRepository.fetchAllVehicleLocations();
      if (!mounted) return;
      setState(() {
        _vehicles = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchVehicles,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: const [
                      Text('Unable to load vehicle list.',
                          style: TextStyle(color: _iconGray)),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _vehicles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionHeader(
                              title: 'Vehicles',
                              subtitle:
                                  'Live feed from vehicle tracking API',
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }
                      final vehicle = _vehicles[index - 1];
                      return _VehicleTile(vehicle: vehicle);
                    },
                  ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final status = _vehicleStateFor(vehicle);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _softGreen.withValues(alpha: 0.45),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.registrationNumber ?? 'Vehicle ${vehicle.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: _iconGray),
                    const SizedBox(width: 4),
                    Text(
                      _formatRelative(vehicle.lastUpdated),
                      style: const TextStyle(color: _iconGray, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _StatusPill(state: status),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MORE SCREEN
// ---------------------------------------------------------------------------

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <_MoreItem>[
      _MoreItem(Icons.person_outline, 'Profile'),
      _MoreItem(Icons.notifications_none, 'Notifications'),
      _MoreItem(Icons.settings_outlined, 'Settings'),
      _MoreItem(Icons.support_agent, 'Support'),
      _MoreItem(Icons.logout, 'Logout'),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'More',
              subtitle: 'Manage your profile, alerts and support',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    Icon(item.icon, color: _primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _iconGray),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
// ---------------------------------------------------------------------------
// HELPERS & MODELS
// ---------------------------------------------------------------------------

class _DashboardData {
  const _DashboardData({this.summary, this.vehicles = const []});

  const _DashboardData.empty() : this();

  final WasteSummary? summary;
  final List<VehicleModel> vehicles;

  Map<_VehicleState, int> get statusCounts => countByStatus(vehicles);

  static Map<_VehicleState, int> countByStatus(List<VehicleModel> vehicles) {
    final counts = {
      _VehicleState.running: 0,
      _VehicleState.idle: 0,
      _VehicleState.parked: 0,
      _VehicleState.nodata: 0,
    };
    for (final vehicle in vehicles) {
      final state = _vehicleStateFor(vehicle);
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return counts;
  }
}

class _WasteSlice {
  const _WasteSlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _WasteDonutPainter extends CustomPainter {
  const _WasteDonutPainter({required this.slices});

  final List<_WasteSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total == 0) return;

    const strokeWidth = 22.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweepAngle = (slice.value / total) * 2 * math.pi;
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
  bool shouldRepaint(covariant _WasteDonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _StatusCount {
  const _StatusCount({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
}

enum _VehicleState { running, idle, parked, nodata }

_VehicleState _vehicleStateFor(VehicleModel vehicle) {
  final raw = vehicle.status?.toLowerCase().trim() ?? '';
  if (raw.contains('run')) return _VehicleState.running;
  if (raw.contains('idle') || raw == 'on') return _VehicleState.idle;
  if (raw.contains('park') || raw.contains('stop') || raw.contains('off')) {
    return _VehicleState.parked;
  }
  return _VehicleState.nodata;
}

Color _vehicleStateColor(_VehicleState state) {
  switch (state) {
    case _VehicleState.running:
      return _primaryGreen;
    case _VehicleState.idle:
      return _softYellow;
    case _VehicleState.parked:
      return _softRed;
    case _VehicleState.nodata:
      return _iconGray;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.state, this.count});

  final _VehicleState state;
  final int? count;

  String get _label {
    switch (state) {
      case _VehicleState.running:
        return 'Running';
      case _VehicleState.idle:
        return 'Idle';
      case _VehicleState.parked:
        return 'Stopped';
      case _VehicleState.nodata:
        return 'No Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _vehicleStateColor(state).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _vehicleStateColor(state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count != null ? '$_label (${count!})' : _label,
            style: TextStyle(
              color: _vehicleStateColor(state),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry(this.title, this.subtitle, this.tone);

  final String title;
  final String subtitle;
  final ActivityTone tone;

  Color get color =>
      tone == ActivityTone.success ? _primaryGreen : _softYellow;
  IconData get icon => tone == ActivityTone.success
      ? Icons.check_circle_outline
      : Icons.warning_amber_outlined;
}

enum ActivityTone { success, warning }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: _iconGray),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softCardShadow(),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          icon: const Icon(Icons.search, color: _iconGray),
        ),
      ),
    );
  }
}

String _formatRelative(String? raw) {
  if (raw == null || raw.isEmpty) return 'Just now';
  try {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final now = DateTime.now();
    final difference = now.difference(parsed);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  } catch (_) {
    return raw;
  }
}
