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

  _MapThemeOption _selectedTheme = _MapThemeOption.standard;
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

  // --- Vehicle list (filtered) modal ---
  void _showVehicleDetailsModal(BuildContext context) {
    final bloc = context.read<VehicleBloc>();
    final state = bloc.state;

    List<VehicleModel> list = const [];
    VehicleFilter filter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      filter = state.activeFilter;
      list = state.vehicles.where((v) {
        final s = (v.status ?? '').toLowerCase();
        switch (filter) {
          case VehicleFilter.all:
            return true;
          case VehicleFilter.running:
            return s == 'running';
          case VehicleFilter.idle:
            return s == 'idle';
          case VehicleFilter.parked:
            return s == 'parked';
          case VehicleFilter.noData:
            return s == 'no data';
        }
      }).toList(growable: false);
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        if (state is! VehicleLoaded) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No vehicle data loaded.',
                  style: theme.textTheme.bodyLarge),
            ),
          );
        }
        if (list.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No vehicles found for filter: ${filter.name.toUpperCase()}',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }

        return SafeArea(
          child: BlocProvider.value(
            value: bloc,
            child: FractionallySizedBox(
              heightFactor: 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filter.name.toUpperCase()} Vehicles',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '${list.length}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final vehicle = list[index];
                        final color = bloc.getStatusColor(vehicle.status);
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.local_shipping, color: color),
                          title: Text(vehicle.registrationNumber ?? 'Unknown'),
                          subtitle: Text(
                            'Last update: ${vehicle.lastUpdated ?? 'N/A'}',
                          ),
                          trailing: Text(
                            (vehicle.status ?? 'NO DATA').toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            bloc.add(VehicleSelectionUpdated(vehicle.id));
                            Navigator.of(sheetCtx).maybePop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  int _countVehiclesInGamma(List<VehicleModel> vehicles) {
    return vehicles.where(_isVehicleInsideGamma).length;
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
        appBar: AppBar(
          // --- FIX: Added Back Button ---
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
          title: const Text('Live Vehicle Tracking',
              style: TextStyle(color: Colors.white)),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // --- FIX: Added Details Icon Button ---
            BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Show Vehicle List',
                  icon:
                      const Icon(Icons.list_alt_outlined, color: Colors.white),
                  onPressed: () {
                    _showVehicleDetailsModal(context);
                  },
                );
              },
            )
          ],
        ),
        body: BlocBuilder<VehicleBloc, VehicleState>(
          builder: (context, state) {
            // --- FIX: Wrap body in Padding and Card ---
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // --- END FIX ---
                child: Stack(
                  children: [
                    _buildMap(context, state),
                    _buildFilterChips(context, state),
                    _buildMapStyleSelector(state),
                    _buildZoomControls(state),
                    if (state is VehicleLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (state is VehicleError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ),
                    _buildVehicleInfoPanel(context, state),
                  ],
                ),
              ),
            );
          },
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

    final markers = <Marker>[
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
        width: 140,
        height: 140,
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

  // --- FILTER CHIPS ---
  Widget _buildFilterChips(BuildContext context, VehicleState state) {
    final theme = Theme.of(context);
    final bloc = context.read<VehicleBloc>();

    List<VehicleModel> vehicles = const [];
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      vehicles = state.vehicles;
      activeFilter = state.activeFilter;
    }

    final vehiclesInGamma = _countVehiclesInGamma(vehicles);

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
                  label: '$vehiclesInGamma in geofence',
                ),
                _StatPill(
                  icon: Icons.local_shipping_outlined,
                  label: '${vehicles.length} tracked',
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

  Widget _buildMapStyleSelector(VehicleState state) {
    final theme = Theme.of(context);
    final hasSelection =
        state is VehicleLoaded && state.selectedVehicle != null;
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
