import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart'; // <-- Import GoRouter
import 'package:iwms_citizen_app/core/di.dart';
import 'package:iwms_citizen_app/data/models/vehicle_model.dart';
import 'package:iwms_citizen_app/logic/vehicle_tracking/vehicle_bloc.dart';
import 'package:iwms_citizen_app/logic/vehicle_tracking/vehicle_event.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../core/geofence_config.dart';
import '../../../router/app_router.dart';
import '../../../data/models/site_polygon.dart';
import '../../../data/repositories/site_repository.dart';
import '../../../shared/widgets/home_base_marker.dart';
import '../../../shared/widgets/tracking_filter_chip_button.dart';
import '../../../shared/widgets/tracking_view_shell.dart';

class MapScreen extends StatefulWidget {
  final String? driverName;
  final String? vehicleNumber;

  const MapScreen({
    super.key,
    this.driverName,
    this.vehicleNumber,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _gammaCenter = GammaGeofenceConfig.center;

  _MapThemeOption _selectedTheme = _MapThemeOption.light;
  static const Map<_MapThemeOption, _MapThemeConfig> _mapThemes = {
    _MapThemeOption.standard: _MapThemeConfig(
      label: 'Standard',
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      attribution: '© OpenStreetMap contributors',
    ),
    _MapThemeOption.light: _MapThemeConfig(
      label: 'Light',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      subdomains: ['a', 'b', 'c', 'd'],
      attribution: '© OpenStreetMap, © CARTO',
    ),
  };

  // Site polygons from API
  List<SitePolygon> _sites = const [];
  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final repo = getIt<SiteRepository>();
    final result = await repo.fetchSites();
    if (mounted) setState(() => _sites = result);
  }

  Widget _buildGammaFacilityMarker() {
    return const HomeBaseMarker(size: 40);
  }

  Iterable<Marker> _buildArcMarkers(LatLng start, LatLng end) sync* {
    final arcPoints = _generateArcPoints(start, end);
    for (var i = 1; i < arcPoints.length - 1; i += 2) {
      final point = arcPoints[i];
      yield Marker(
        width: 10,
        height: 10,
        point: point,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: const Color(0xFF0B5721).withValues(alpha: 0.7),
              width: 1,
            ),
          ),
        ),
      );
    }
  }

  List<LatLng> _generateArcPoints(
    LatLng start,
    LatLng end, {
    int segments = 20,
    double curveStrength = 0.003,
  }) {
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    final control = LatLng(
      midLat - dy * curveStrength,
      midLng + dx * curveStrength,
    );

    final points = <LatLng>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final invT = 1 - t;
      final lat = invT * invT * start.latitude +
          2 * invT * t * control.latitude +
          t * t * end.latitude;
      final lng = invT * invT * start.longitude +
          2 * invT * t * control.longitude +
          t * t * end.longitude;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = (currentZoom + 0.6).clamp(10.0, 18.0).toDouble();
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = (currentZoom - 0.6).clamp(10.0, 18.0).toDouble();
    _mapController.move(_mapController.camera.center, targetZoom);
  }

  void _recenterOnGamma() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 14.0 ? 14.0 : currentZoom;
    _mapController.move(_gammaCenter, targetZoom);
  }

  void _setTheme(_MapThemeOption theme) {
    if (_selectedTheme == theme) return;
    setState(() {
      _selectedTheme = theme;
    });
  }

  void _focusOnVehicle(VehicleModel vehicle) {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 16.0 ? 16.0 : currentZoom;
    _mapController.move(
      LatLng(vehicle.latitude, vehicle.longitude),
      targetZoom,
    );
  }

  Color _polygonFillFor(String name) {
    final upper = name.toUpperCase();
    if (upper.startsWith('GAMMA')) return Colors.blue.withValues(alpha: 0.10);
    if (upper.startsWith('ALPHA')) return Colors.green.withValues(alpha: 0.10);
    if (upper.startsWith('BETA')) return Colors.orange.withValues(alpha: 0.10);
    return kPrimaryColor.withValues(alpha: 0.08);
  }

  Color _polygonStrokeFor(String name) {
    final upper = name.toUpperCase();
    if (upper.startsWith('GAMMA')) return Colors.blue;
    if (upper.startsWith('ALPHA')) return Colors.green;
    if (upper.startsWith('BETA')) return Colors.deepOrange;
    return kPrimaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<VehicleBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SafeArea(
          child: BlocBuilder<VehicleBloc, VehicleState>(
            builder: (context, state) {
              final size = MediaQuery.of(context).size;
              final double headerHeight = size.height * 0.2;
              final totalVehicles =
                  state is VehicleLoaded ? state.vehicles.length : 0;
              final selectedVehicle =
                  state is VehicleLoaded ? state.selectedVehicle : null;
              final String headline = selectedVehicle != null
                  ? 'Tracking ${selectedVehicle.registrationNumber ?? 'vehicle'}'
                  : 'Live vehicle tracking';
              final statusPrimary =
                  selectedVehicle?.lastUpdated ?? 'Refreshing telemetry';
              final statusSecondary = totalVehicles > 0
                  ? '$totalVehicles active'
                  : 'Awaiting signal';

              return Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: TrackingHeroHeader(
                      contextLabel:
                          widget.vehicleNumber ?? 'Gamma Collection Zone',
                      headline: headline,
                      statusPrimary: statusPrimary,
                      statusSecondary: statusSecondary,
                      statusContent: _buildHeaderFilterSection(context, state),
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutePaths.citizenHome);
                        }
                      },
                      onRefresh: () => context
                          .read<VehicleBloc>()
                          .add(const VehicleFetchRequested(showLoading: true)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            children: [
                              _buildMap(context, state),
                              _buildMapStyleSelector(state),
                              _buildZoomControls(state),
                              if (selectedVehicle != null)
                                Align(
                                  alignment: Alignment.center,
                                  child: TrackingSpeechBubble(
                                    message:
                                        '${selectedVehicle.registrationNumber ?? 'Vehicle'} en route',
                                    icon: Icons.local_shipping_rounded,
                                  ),
                                ),
                              if (state is VehicleLoading)
                                const Center(
                                    child: CircularProgressIndicator()),
                              if (state is VehicleError)
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              _buildVehicleInfoPanel(context, state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- MAP WIDGET ---
  Widget _buildMap(BuildContext context, VehicleState state) {
    List<VehicleModel> vehiclesToShow = [];
    VehicleModel? selectedVehicle;
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      selectedVehicle = state.selectedVehicle;
      activeFilter = state.activeFilter;

      vehiclesToShow = state.vehicles.where((vehicle) {
        final status = vehicle.status?.toLowerCase() ?? 'no data';
        switch (activeFilter) {
          case VehicleFilter.all:
            return true;
          case VehicleFilter.running:
            return status == 'running';
          case VehicleFilter.idle:
            return status == 'idle';
          case VehicleFilter.parked:
            return status == 'parked';
          case VehicleFilter.noData:
            return status == 'no data';
        }
      }).toList();
    }

    final arcMarkers = <Marker>[];
    if (selectedVehicle != null) {
      final vehiclePoint =
          LatLng(selectedVehicle.latitude, selectedVehicle.longitude);
      if (GammaGeofenceConfig.contains(vehiclePoint)) {
        arcMarkers.addAll(_buildArcMarkers(_gammaCenter, vehiclePoint));
      }
    }

    final markers = <Marker>[
      ...arcMarkers,
      for (final vehicle in vehiclesToShow)
        Marker(
          width: 110,
          height: 120,
          point: LatLng(vehicle.latitude, vehicle.longitude),
          child: GestureDetector(
            onTap: () {
              context
                  .read<VehicleBloc>()
                  .add(VehicleSelectionUpdated(vehicle.id));
            },
            child: _VehicleMarker(
              vehicle: vehicle,
              isSelected: selectedVehicle?.id == vehicle.id,
              getVehicleStatusColor: context.read<VehicleBloc>().getStatusColor,
            ),
          ),
        ),
      Marker(
        width: 68,
        height: 68,
        point: _gammaCenter,
        child: _buildGammaFacilityMarker(),
      ),
    ];

    final themeConfig = _mapThemes[_selectedTheme]!;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _gammaCenter,
        initialZoom: 14.5,
        minZoom: 10,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (tapPosition, point) {
          context.read<VehicleBloc>().add(const VehicleSelectionUpdated(null));
        },
      ),
      children: [
        TileLayer(
          urlTemplate: themeConfig.urlTemplate,
          subdomains: themeConfig.subdomains,
        ),
        if (_sites.isNotEmpty)
          PolygonLayer(
            polygons: _sites
                .map((s) => Polygon(
                      points: s.points,
                      color: _polygonFillFor(s.name),
                      borderColor: _polygonStrokeFor(s.name),
                      borderStrokeWidth: 2.2,
                    ))
                .toList(),
          )
        else
          PolygonLayer(
            polygons: [
              Polygon(
                points: GammaGeofenceConfig.polygon,
                color: kPrimaryColor.withValues(alpha: 0.08),
                borderColor: kPrimaryColor.withValues(alpha: 0.55),
                borderStrokeWidth: 2.5,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(
              themeConfig.attribution,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  // --- HEADER FILTER SECTION ---
  Widget _buildHeaderFilterSection(BuildContext context, VehicleState state) {
    final bloc = context.read<VehicleBloc>();
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      activeFilter = state.activeFilter;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: VehicleFilter.values.map((filter) {
          final isSelected = activeFilter == filter;
          final count = bloc.countVehiclesByFilter(filter);
          final label =
              '${filter.name[0].toUpperCase()}${filter.name.substring(1)} ($count)';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TrackingFilterChipButton(
              label: label,
              selected: isSelected,
              onTap: () => bloc.add(VehicleFilterUpdated(filter)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapStyleSelector(VehicleState state) {
    final theme = Theme.of(context);
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final double bottomOffset = 16.0 + safeBottom;

    return Positioned(
      bottom: bottomOffset,
      left: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            alignment: WrapAlignment.start,
            children: _mapThemes.entries.map((entry) {
              final option = entry.key;
              final config = entry.value;
              final isSelected = _selectedTheme == option;

              return ChoiceChip(
                label: Text(config.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _setTheme(option);
                  }
                },
                selectedColor: theme.colorScheme.primary,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls(VehicleState state) {
    final hasSelection =
        state is VehicleLoaded && state.selectedVehicle != null;
    final bottomOffset = hasSelection ? 180.0 : 24.0;

    return Positioned(
      bottom: bottomOffset,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
          ),
          const SizedBox(height: 8),
          _MapControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
          ),
          const SizedBox(height: 8),
          _MapControlButton(
            icon: Icons.my_location_outlined,
            onPressed: _recenterOnGamma,
          ),
        ],
      ),
    );
  }

  // --- VEHICLE INFO PANEL ---
  Widget _buildVehicleInfoPanel(BuildContext context, VehicleState state) {
    // ... (This function remains exactly as you wrote it)
    if (state is! VehicleLoaded || state.selectedVehicle == null) {
      return Container();
    }

    final vehicle = state.selectedVehicle!;
    final statusColor =
        context.read<VehicleBloc>().getStatusColor(vehicle.status);

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(18),
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicle.registrationNumber ?? 'Unknown Vehicle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (vehicle.status ?? 'No Data').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: () {
                      context
                          .read<VehicleBloc>()
                          .add(const VehicleSelectionUpdated(null));
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if ((vehicle.address ?? '').isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vehicle.address!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              if ((vehicle.address ?? '').isNotEmpty)
                const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoTag(
                    label: 'Estimated Load',
                    value:
                        '${(vehicle.wasteCapacityKg ?? 0).toStringAsFixed(1)} kg',
                  ),
                  _InfoTag(
                    label: 'Last update',
                    value: vehicle.lastUpdated ?? 'N/A',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _focusOnVehicle(vehicle),
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Focus on vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- VEHICLE MARKER WIDGET ---
class _VehicleMarker extends StatelessWidget {
  // ... (This widget remains exactly as you wrote it)
  final VehicleModel vehicle;
  final bool isSelected;
  final Color Function(String?) getVehicleStatusColor;

  const _VehicleMarker({
    required this.vehicle,
    required this.isSelected,
    required this.getVehicleStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getVehicleStatusColor(vehicle.status);
    final size = isSelected ? 45.0 : 30.0;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vehicle.registrationNumber ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _MapThemeOption { standard, light }

class _MapThemeConfig {
  const _MapThemeConfig({
    required this.label,
    required this.urlTemplate,
    required this.subdomains,
    required this.attribution,
  });

  final String label;
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;
}
