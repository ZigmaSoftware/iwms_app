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

class CitizenAllotedVehicleMapScreen extends StatefulWidget {
  const CitizenAllotedVehicleMapScreen({super.key});

  @override
  State<CitizenAllotedVehicleMapScreen> createState() =>
      _CitizenAllotedVehicleMapScreenState();
}

class _CitizenAllotedVehicleMapScreenState
    extends State<CitizenAllotedVehicleMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _gammaCenter = GammaGeofenceConfig.center;
  _MapThemeOption _selectedTheme = _MapThemeOption.standard;
  LatLng? _lastCameraTarget;
  double? _lastCameraZoom;
  bool _showVehicleDetails = false;

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

  void _setTheme(_MapThemeOption theme) {
    if (_selectedTheme == theme) return;
    setState(() => _selectedTheme = theme);
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

  bool _isVehicleInsideGamma(VehicleModel vehicle) {
    final position = LatLng(vehicle.latitude, vehicle.longitude);
    if (GammaGeofenceConfig.contains(position)) {
      return true;
    }

    final address = vehicle.address?.toLowerCase() ?? '';
    final bool providerFlagged = vehicle.isInsideGeofence &&
        address.contains(GammaGeofenceConfig.addressHint);

    return providerFlagged && GammaGeofenceConfig.isNear(position);
  }

  void _focusOnVehicle(VehicleModel vehicle) {
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 16.0 ? 16.0 : currentZoom;
    _mapController.move(
      LatLng(vehicle.latitude, vehicle.longitude),
      targetZoom,
    );
  }

  void _setVehicleDetailsVisibility(bool visible) {
    if (!mounted) return;
    if (_showVehicleDetails == visible) return;
    setState(() => _showVehicleDetails = visible);
  }

  List<VehicleModel> _allottedVehicles(List<VehicleModel> vehicles) {
    return vehicles.where(_isVehicleInsideGamma).toList(growable: false);
  }

  void _moveCamera(LatLng center, double zoom) {
    final previous = _lastCameraTarget;
    final zoomMatch =
        _lastCameraZoom != null && (_lastCameraZoom! - zoom).abs() < 0.02;
    final positionMatch = previous != null &&
        (center.latitude - previous.latitude).abs() < 0.0001 &&
        (center.longitude - previous.longitude).abs() < 0.0001;

    if (positionMatch && zoomMatch) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(center, zoom);
      _lastCameraTarget = center;
      _lastCameraZoom = zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VehicleBloc>(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.citizenHome);
              }
            },
          ),
          title: const Text(
            'Track Assigned Vehicle',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: BlocBuilder<VehicleBloc, VehicleState>(
          builder: (context, state) {
            final allVehicles = state is VehicleLoaded
                ? state.vehicles
                : const <VehicleModel>[];
            final assignedVehicles = _allottedVehicles(allVehicles);
            final assignedVehicle =
                assignedVehicles.isNotEmpty ? assignedVehicles.first : null;
            final cameraTarget = assignedVehicle != null
                ? LatLng(assignedVehicle.latitude, assignedVehicle.longitude)
                : _gammaCenter;
            final targetZoom = assignedVehicle != null ? 15.0 : 13.6;
            _moveCamera(cameraTarget, targetZoom);

            final showError = state is VehicleError;
            final hasAssigned = assignedVehicle != null;
            final assignmentsCount = assignedVehicles.length;
            if (!hasAssigned && _showVehicleDetails) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _setVehicleDetailsVisibility(false);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    _buildMap(context, assignedVehicle),
                    _buildFilterChips(
                      context,
                      state,
                      assignmentsCount,
                      allVehicles.length,
                    ),
                    _buildMapStyleSelector(state, hasAssigned),
                    _buildZoomControls(state, hasAssigned),
                    if (state is VehicleLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (showError) _buildErrorState(state.message),
                    if (!hasAssigned && state is VehicleLoaded)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Waiting for your allocated collector to enter ${GammaGeofenceConfig.name}.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ),
                      ),
                    _buildVehicleInfoPanel(context, assignedVehicle),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, VehicleModel? vehicle) {
    final theme = Theme.of(context);
    final themeConfig = _mapThemes[_selectedTheme]!;
    final markers = <Marker>[];
    if (vehicle != null) {
      markers.add(
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
      );
    }
    markers.add(
      Marker(
        width: 140,
        height: 140,
        point: _gammaCenter,
        child: _buildGammaFacilityMarker(),
      ),
    );

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
        onTap: (tapPos, point) {
          context.read<VehicleBloc>().add(const VehicleSelectionUpdated(null));
          _setVehicleDetailsVisibility(false);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: themeConfig.urlTemplate,
          subdomains: themeConfig.subdomains,
        ),
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
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(themeConfig.attribution),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    VehicleState state,
    int vehiclesInGeofence,
    int totalVehicles,
  ) {
    final theme = Theme.of(context);
    final bloc = context.read<VehicleBloc>();
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      activeFilter = state.activeFilter;
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
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
                        '${GammaGeofenceConfig.name} facility',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Blue Planet Integrated Waste Management Facility',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _recenterOnGamma,
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  label: const Text('Focus'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatPill(
                  icon: Icons.location_on_outlined,
                  label: '$vehiclesInGeofence in geofence',
                ),
                _StatPill(
                  icon: Icons.local_shipping_outlined,
                  label: '$totalVehicles tracked',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: VehicleFilter.values.map((filter) {
                  final isSelected = activeFilter == filter;
                  final count = bloc.countVehiclesByFilter(filter);
                  final label =
                      '${filter.name[0].toUpperCase()}${filter.name.substring(1)} ($count)';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          bloc.add(VehicleFilterUpdated(filter));
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStyleSelector(VehicleState state, bool hasDetails) {
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

  Widget _buildZoomControls(VehicleState state, bool hasDetails) {
    final bottomOffset = hasDetails ? 180.0 : 24.0;

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

  Widget _buildVehicleInfoPanel(
    BuildContext context,
    VehicleModel? vehicle,
  ) {
    if (vehicle == null || !_showVehicleDetails) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final statusColor =
        context.read<VehicleBloc>().getStatusColor(vehicle.status);
    final registration = vehicle.registrationNumber ?? 'Vehicle ${vehicle.id}';
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Assigned vehicle • $registration',
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

  Widget _buildGammaFacilityMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.home_work_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            GammaGeofenceConfig.name,
            style: TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignedVehicleMarker extends StatelessWidget {
  const _AssignedVehicleMarker({
    required this.vehicle,
    required this.statusColor,
  });

  final VehicleModel vehicle;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final registration = vehicle.registrationNumber ?? 'Unknown';
    final driver = vehicle.driverName ?? 'Pending';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor),
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
                registration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                driver,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor.withValues(alpha: 0.9),
                    ),
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
