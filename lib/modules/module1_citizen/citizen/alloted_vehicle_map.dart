import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../../core/geofence_config.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../logic/vehicle_tracking/vehicle_bloc.dart';
import '../../../logic/vehicle_tracking/vehicle_event.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/home_base_marker.dart';
import '../../../shared/widgets/tracking_filter_chip_button.dart';
import '../../../shared/widgets/tracking_view_shell.dart';

class CitizenAllotedVehicleMapScreen extends StatefulWidget {
  const CitizenAllotedVehicleMapScreen({super.key});

  @override
  State<CitizenAllotedVehicleMapScreen> createState() =>
      _CitizenAllotedVehicleMapScreenState();
}

class _CitizenAllotedVehicleMapScreenState
    extends State<CitizenAllotedVehicleMapScreen> {
  // ---------------------------------------------------------------------------
  // CORE PROPERTIES
  // ---------------------------------------------------------------------------

  final MapController _mapController = MapController();
  final LatLng _gammaCenter = GammaGeofenceConfig.center;

  _MapThemeOption _selectedTheme = _MapThemeOption.light;

  // Track camera state to avoid repeated jumps
  LatLng? _lastCameraTarget;
  double? _lastCameraZoom;

  // Info panel visibility
  bool _showVehicleDetails = false;

  // Hybrid auto-fit logic
  Timer? _idleTimer;
  bool _userHasInteracted = false; // disables auto-fit for 30 sec after pan

  // New: track if auto-fit has already been done once
  bool _initialFitDone = false;

  // When camera is moving programmatically, avoid marking it as user move
  bool _programmaticCameraMove = false;

  // ---------------------------------------------------------------------------
  // MAP THEMES
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // INIT + DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Track when user interacts with map → disable auto-fit for 30 seconds
    _attachMapInteractionTracker();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // USER INTERACTION TRACKER
  // Prevent auto-fit for 30 seconds after user manually pans/zooms.
  // ---------------------------------------------------------------------------

  void _attachMapInteractionTracker() {
    _mapController.mapEventStream.listen((event) {
      if (_programmaticCameraMove) {
        // Ignore events triggered by code
        return;
      }

      // User actually moved or zoomed
      _userHasInteracted = true;

      // Reset 30s timer
      _idleTimer?.cancel();
      _idleTimer = Timer(const Duration(seconds: 30), () {
        _userHasInteracted = false;
      });
    });
  }

  // ---------------------------------------------------------------------------
  // ZOOM + CAMERA MOTION HELPERS
  // ---------------------------------------------------------------------------

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _moveCamera(
      _mapController.camera.center,
      (currentZoom + 0.6).clamp(10.0, 18.0).toDouble(),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _moveCamera(
      _mapController.camera.center,
      (currentZoom - 0.6).clamp(10.0, 18.0).toDouble(),
    );
  }

  void _recenterOnGamma() {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 14.0 ? 14.0 : currentZoom;
    _moveCamera(_gammaCenter, targetZoom);
  }

  // ---------------------------------------------------------------------------
  // CORE CAMERA MOVE WRAPPER
  // Handles animation + updates last target + avoids jitter
  // ---------------------------------------------------------------------------

  void _moveCamera(LatLng center, double zoom, {bool animate = false}) {
    final prev = _lastCameraTarget;
    final zoomMatch =
        _lastCameraZoom != null && (_lastCameraZoom! - zoom).abs() < 0.01;

    final posMatch = prev != null &&
        (prev.latitude - center.latitude).abs() < 0.0001 &&
        (prev.longitude - center.longitude).abs() < 0.0001;

    if (posMatch && zoomMatch) return;

    _programmaticCameraMove = true;

    // flutter_map v7: no animateTo, fall back to an immediate move
    _mapController.move(center, zoom);

    Future.delayed(const Duration(milliseconds: 300), () {
      _programmaticCameraMove = false;
    });

    _lastCameraTarget = center;
    _lastCameraZoom = zoom;
  }

  // ---------------------------------------------------------------------------
  // AUTO-FIT FOR HOME + VEHICLE
  // Called only:
  // 1) when vehicle first appears from geofence
  // 2) OR after 30 seconds of no user interaction
  // ---------------------------------------------------------------------------

  void _fitHomeAndVehicle(VehicleModel vehicle, {bool force = false}) {
    if (!force) {
      if (_userHasInteracted) return;
      if (_initialFitDone) return; // prevents repeated fit
    }

    final home = _gammaCenter;
    final veh = LatLng(vehicle.latitude, vehicle.longitude);

    final bounds = LatLngBounds.fromPoints([home, veh]);

    _programmaticCameraMove = true;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
        maxZoom: 16.2,
        minZoom: 13.4,
      ),
    );

    try {
      final camera = _mapController.camera;
      _lastCameraTarget = camera.center;
      _lastCameraZoom = camera.zoom;
    } catch (_) {
      _lastCameraTarget = null;
      _lastCameraZoom = null;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _programmaticCameraMove = false;
    });

    _initialFitDone = true;
  }

  void _setVehicleDetailsVisibility(bool visible) {
    if (_showVehicleDetails == visible) return;
    setState(() {
      _showVehicleDetails = visible;
    });
  }

  void _focusOnVehicle(VehicleModel vehicle) {
    final target = LatLng(vehicle.latitude, vehicle.longitude);
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 16.0 ? 16.0 : currentZoom;
    _moveCamera(target, targetZoom, animate: true);
  }
  // ---------------------------------------------------------------------------
  // VEHICLE FILTERING LOGIC (unchanged behavior)
  // ---------------------------------------------------------------------------

  bool _isVehicleInsideGamma(VehicleModel vehicle) {
    final pos = LatLng(vehicle.latitude, vehicle.longitude);
    if (GammaGeofenceConfig.contains(pos)) return true;

    final address = vehicle.address?.toLowerCase() ?? '';
    final flagged = vehicle.isInsideGeofence &&
        address.contains(GammaGeofenceConfig.addressHint);

    return flagged && GammaGeofenceConfig.isNear(pos);
  }

  List<VehicleModel> _allottedVehicles(List<VehicleModel> all) {
    return all.where(_isVehicleInsideGamma).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // UI BUILD START
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VehicleBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SafeArea(
          child: BlocConsumer<VehicleBloc, VehicleState>(
            listenWhen: (previous, current) => previous != current,
            listener: (context, state) {
              final allVehicles = state is VehicleLoaded
                  ? state.vehicles
                  : const <VehicleModel>[];

              final assignedVehicles = _allottedVehicles(allVehicles);
              final assignedVehicle =
                  assignedVehicles.isNotEmpty ? assignedVehicles.first : null;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (assignedVehicle != null) {
                  _fitHomeAndVehicle(
                    assignedVehicle,
                    force: false,
                  );
                } else {
                  _moveCamera(_gammaCenter, 13.5, animate: false);
                  _initialFitDone = false;
                }

                if (assignedVehicle == null && _showVehicleDetails) {
                  _setVehicleDetailsVisibility(false);
                }
              });
            },
            builder: (context, state) {
              // ---------------------------------------------------------------
              // Extract vehicle data
              // ---------------------------------------------------------------

              final allVehicles = state is VehicleLoaded
                  ? state.vehicles
                  : const <VehicleModel>[];

              final assignedVehicles = _allottedVehicles(allVehicles);
              final assignedVehicle =
                  assignedVehicles.isNotEmpty ? assignedVehicles.first : null;

              final hasAssigned = assignedVehicle != null;
              final errorMessage =
                  state is VehicleError ? state.message : null;

              // ---------------------------------------------------------------
              // Header Info
              // ---------------------------------------------------------------

              final size = MediaQuery.of(context).size;
              final headerHeight = size.height * 0.20;

              final headline = hasAssigned
                  ? 'Your collector is en route'
                  : 'Awaiting assigned vehicle';

              final statusPrimary = hasAssigned
                  ? (assignedVehicle.lastUpdated ?? 'Live telemetry')
                  : 'No location yet';

              final statusSecondary =
                  '${assignedVehicles.length} allocated • ${allVehicles.length} total';

              // ---------------------------------------------------------------
              // MAIN UI LAYOUT
              // ---------------------------------------------------------------

              return Column(
                children: [
                  // HEADER
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: TrackingHeroHeader(
                      contextLabel: 'Assigned vehicle',
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

                  // MAP
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
                              _buildMap(context, assignedVehicle),

                              // Map style selector
                              _buildMapStyleSelector(
                                state,
                                hasAssigned,
                              ),

                              _buildZoomControls(
                                state,
                                hasAssigned,
                              ),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: hasAssigned
                                    ? Align(
                                        key: const ValueKey(
                                            'assignedVehicleBubble'),
                                        alignment: Alignment.center,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _setVehicleDetailsVisibility(
                                                  true),
                                          child: TrackingSpeechBubble(
                                            message: assignedVehicle
                                                    .registrationNumber ??
                                                'View details',
                                            icon: Icons
                                                .local_shipping_rounded,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              if (state is VehicleLoading)
                                const Center(
                                    child: CircularProgressIndicator()),

                              if (errorMessage != null)
                                _buildErrorState(errorMessage),

                              // No vehicle assigned → overlay
                              if (!hasAssigned && state is VehicleLoaded)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                    ),
                                    child: Text(
                                      'Waiting for your allocated collector to enter ${GammaGeofenceConfig.name}.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ),
                                ),

                              // Vehicle info panel
                              _buildVehicleInfoPanel(
                                context,
                                assignedVehicle,
                              ),
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

  // ---------------------------------------------------------------------------
  // MAP WIDGET
  // ---------------------------------------------------------------------------

  Widget _buildMap(BuildContext context, VehicleModel? vehicle) {
    final theme = Theme.of(context);
    final themeConfig = _mapThemes[_selectedTheme]!;

    // ---------------------------------------------------------------
    // Arc markers (vehicle inside geofence)
    // ---------------------------------------------------------------
    final arcMarkers = <Marker>[];
    if (vehicle != null) {
      final vPos = LatLng(vehicle.latitude, vehicle.longitude);
      if (GammaGeofenceConfig.contains(vPos)) {
        arcMarkers.addAll(_buildArcMarkers(_gammaCenter, vPos));
      }
    }

    // ---------------------------------------------------------------
    // All map markers
    // ---------------------------------------------------------------
    final markers = <Marker>[
      ...arcMarkers,

      // Assigned vehicle
      if (vehicle != null)
        Marker(
          width: 120,
          height: 136,
          point: LatLng(vehicle.latitude, vehicle.longitude),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _setVehicleDetailsVisibility(true);
            },
            child: _AssignedVehicleMarker(
              vehicle: vehicle,
              statusColor:
                  context.read<VehicleBloc>().getStatusColor(vehicle.status),
            ),
          ),
        ),

      // Home-base marker (size reduced)
      Marker(
        width: 32,
        height: 32,
        point: _gammaCenter,
        child: _buildGammaFacilityMarker(),
      ),
    ];

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
        onTap: (tapPos, tapPoint) {
          _setVehicleDetailsVisibility(false);

          // Clear BLoC selection if implemented
          try {
            context.read<VehicleBloc>().add(
                  const VehicleSelectionUpdated(null),
                );
          } catch (_) {}
        },
        onPointerUp: (_, __) {
          // User touched the map → mark as manual interaction
          _userHasInteracted = true;
          _idleTimer?.cancel();
          _idleTimer = Timer(const Duration(seconds: 30), () {
            _userHasInteracted = false;
          });
        },
      ),
      children: [
        // Base layer
        TileLayer(
          urlTemplate: themeConfig.urlTemplate,
          subdomains: themeConfig.subdomains,
        ),

        // Gamma polygon
        PolygonLayer(
          polygons: [
            Polygon(
              points: GammaGeofenceConfig.polygon,
              borderColor: theme.colorScheme.primary.withValues(alpha: 0.6),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderStrokeWidth: 2.4,
            ),
          ],
        ),

        // Markers
        if (markers.isNotEmpty) MarkerLayer(markers: markers),

        // Attribution
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(themeConfig.attribution),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER FILTER PILL ROW
  // ---------------------------------------------------------------------------

  Widget _buildHeaderFilterSection(
    BuildContext context,
    VehicleState state,
  ) {
    final bloc = context.read<VehicleBloc>();
    VehicleFilter active = VehicleFilter.all;

    if (state is VehicleLoaded) {
      active = state.activeFilter;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: VehicleFilter.values.map((filter) {
          final selected = active == filter;
          final count = bloc.countVehiclesByFilter(filter);
          final label =
              '${filter.name[0].toUpperCase()}${filter.name.substring(1)} ($count)';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TrackingFilterChipButton(
              label: label,
              selected: selected,
              onTap: () => bloc.add(VehicleFilterUpdated(filter)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP STYLE SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildMapStyleSelector(VehicleState state, bool hasVehicle) {
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
                    setState(() => _selectedTheme = option);
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

  // ---------------------------------------------------------------------------
  // ZOOM CONTROLS
  // ---------------------------------------------------------------------------

  Widget _buildZoomControls(VehicleState state, bool hasVehicle) {
    final double bottomOffset = hasVehicle ? 180.0 : 24.0;

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

  // ---------------------------------------------------------------------------
  // VEHICLE INFO PANEL
  // ---------------------------------------------------------------------------

  Widget _buildVehicleInfoPanel(
    BuildContext context,
    VehicleModel? vehicle,
  ) {
    if (vehicle == null || !_showVehicleDetails) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final statusColor =
        context.read<VehicleBloc>().getStatusColor(vehicle.status);

    final reg = vehicle.registrationNumber ?? 'Vehicle ${vehicle.id}';
    final driver = vehicle.driverName ?? 'Driver info pending';
    final lastUpdated = vehicle.lastUpdated ?? 'Updated moments ago';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      bottom: 20,
      left: 20,
      right: 20,
      height: 220,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(18),
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              GestureDetector(
                onTap: () => _setVehicleDetailsVisibility(false),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Assigned vehicle • $reg',
                      style: theme.textTheme.titleMedium?.copyWith(
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
                      (vehicle.status ?? 'No data').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Driver row
              Row(
                children: [
                  Icon(Icons.person_outline,
                      color: theme.colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      driver,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoTag(
                    label: 'Last seen',
                    value: lastUpdated,
                  ),
                  _InfoTag(
                    label: 'Location',
                    value: vehicle.address ?? GammaGeofenceConfig.name,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _focusOnVehicle(vehicle),
                  icon: const Icon(Icons.location_searching_outlined),
                  label: const Text('Center on vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR PANEL
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String message) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOME MARKER (SIZE REDUCED)
  // ---------------------------------------------------------------------------

  Widget _buildGammaFacilityMarker() {
    return const HomeBaseMarker(size: 22); // Reduced
  }

  // ---------------------------------------------------------------------------
  // ARC MARKERS (SAME LOGIC)
  // ---------------------------------------------------------------------------

  Iterable<Marker> _buildArcMarkers(LatLng start, LatLng end) sync* {
    final arcPoints = _generateArcPoints(start, end);

    for (var i = 1; i < arcPoints.length - 1; i += 2) {
      yield Marker(
        width: 10,
        height: 10,
        point: arcPoints[i],
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
  // ---------------------------------------------------------------------------
  // ARC PATH GENERATOR
  // ---------------------------------------------------------------------------

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

    // Control point for gentle curve
    final control = LatLng(
      midLat - dy * curveStrength,
      midLng + dx * curveStrength,
    );

    final pts = <LatLng>[];

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final invT = 1 - t;

      final lat = invT * invT * start.latitude +
          2 * invT * t * control.latitude +
          t * t * end.latitude;

      final lng = invT * invT * start.longitude +
          2 * invT * t * control.longitude +
          t * t * end.longitude;

      pts.add(LatLng(lat, lng));
    }

    return pts;
  }
}

// ============================================================================
// ASSIGNED VEHICLE MARKER
// ============================================================================

class _AssignedVehicleMarker extends StatelessWidget {
  const _AssignedVehicleMarker({
    required this.vehicle,
    required this.statusColor,
  });

  final VehicleModel vehicle;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final reg = vehicle.registrationNumber ?? 'Unknown';
    final driver = vehicle.driverName ?? 'Pending';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.local_shipping,
                color: statusColor,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                reg,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                driver,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: statusColor.withValues(alpha: 0.9)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Icon(Icons.place, color: statusColor, size: 22),
      ],
    );
  }
}

// ============================================================================
// MAP CONTROL BUTTON
// ============================================================================

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

// ============================================================================
// INFO TAG
// ============================================================================

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.label,
    required this.value,
  });

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

// ============================================================================
// ENUMS & CONFIG
// ============================================================================

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
