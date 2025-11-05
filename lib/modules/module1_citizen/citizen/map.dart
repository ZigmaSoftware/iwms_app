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
  final LatLng _userLocation = const LatLng(11.3410, 77.7172); // Erode

  // --- NEW: Function to show details modal ---
  void _showVehicleDetailsModal(BuildContext context, VehicleState state) {
    List<VehicleModel> vehiclesToShow = [];
    String title = "Vehicle Details";
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      activeFilter = state.activeFilter;
      // Apply the same filter logic as your map
      vehiclesToShow = state.vehicles.where((v) {
        final status = v.status?.toLowerCase() ?? 'no data';
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
      title = "${activeFilter.name.toUpperCase()} Vehicles";
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        if (state is! VehicleLoaded) {
          return const Center(child: Text('No vehicle data loaded.'));
        }
        if (vehiclesToShow.isEmpty) {
          return Center(
              child: Text(
                  'No vehicles found for filter: ${activeFilter.name.toUpperCase()}'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: vehiclesToShow.length,
                itemBuilder: (context, index) {
                  final vehicle = vehiclesToShow[index];
                  final statusColor = context
                      .read<VehicleBloc>()
                      .getStatusColor(vehicle.status);
                  return ListTile(
                    leading: Icon(
                      Icons.local_shipping,
                      color: statusColor,
                    ),
                    title: Text(vehicle.registrationNumber ?? 'Unknown'),
                    subtitle: Text('Last Update: ${vehicle.lastUpdated}'),
                    trailing:
                        Text(vehicle.status?.toUpperCase() ?? 'NO DATA'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
            onPressed: () => context.pop(),
          ),
          title:
              const Text('Live Vehicle Tracking', style: TextStyle(color: Colors.white)),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // --- FIX: Added Details Icon Button ---
            BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Show Vehicle List',
                  icon: const Icon(Icons.list_alt_outlined, color: Colors.white),
                  onPressed: () {
                    _showVehicleDetailsModal(context, state);
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
    // ... (This function remains exactly as you wrote it)
    List<VehicleModel> vehiclesToShow = [];
    VehicleModel? selectedVehicle;
    VehicleFilter activeFilter = VehicleFilter.all;

    if (state is VehicleLoaded) {
      selectedVehicle = state.selectedVehicle;
      activeFilter = state.activeFilter;

      vehiclesToShow = state.vehicles.where((v) {
        final status = v.status?.toLowerCase() ?? 'no data';
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

    final markers = vehiclesToShow.map((vehicle) {
      final isSelected = selectedVehicle?.id == vehicle.id;
      return Marker(
        width: 100,
        height: 80,
        point: LatLng(vehicle.latitude, vehicle.longitude),
        child: GestureDetector(
          onTap: () {
            context
                .read<VehicleBloc>()
                .add(VehicleSelectionUpdated(vehicle.id));
          },
          child: _VehicleMarker(
            vehicle: vehicle,
            isSelected: isSelected,
            getVehicleStatusColor: context.read<VehicleBloc>().getStatusColor,
          ),
        ),
      );
    }).toList();

    markers.add(Marker(
      width: 80,
      height: 80,
      point: _userLocation,
      child: const Column(
        children: [
          Icon(Icons.person_pin_circle, color: Colors.green, size: 35),
          Text('You',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    ));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation,
        initialZoom: 14.0,
        onTap: (tapPosition, point) {
          context.read<VehicleBloc>().add(const VehicleSelectionUpdated(null));
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // --- FILTER CHIPS ---
  Widget _buildFilterChips(BuildContext context, VehicleState state) {
    // ... (This function remains exactly as you wrote it)
    if (state is! VehicleLoaded) {
      return Container();
    }

    final bloc = context.read<VehicleBloc>();

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: VehicleFilter.values.map((filter) {
            final count = bloc.countVehiclesByFilter(filter);
            final isSelected = state.activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text('${filter.name.toUpperCase()} ($count)'),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) {
                    bloc.add(VehicleFilterUpdated(filter));
                  }
                },
                backgroundColor: Colors.white,
                selectedColor: kPrimaryColor.withOpacity(0.8),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : kTextColor,
                  fontWeight: FontWeight.bold,
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
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
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.registrationNumber ?? 'Unknown Vehicle',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vehicle.status?.toUpperCase() ?? 'NO DATA',
                    style: TextStyle(
                        fontSize: 16,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Load: ${vehicle.wasteCapacityKg ?? 0} kg',
                style: const TextStyle(fontSize: 16, color: kTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Update: ${vehicle.lastUpdated ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: kTextColor),
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
                        color: Colors.black.withOpacity(0.5),
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