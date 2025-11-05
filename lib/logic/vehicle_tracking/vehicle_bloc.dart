import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
// FIX: Import Events (defines VehicleEvent, VehicleFetchRequested, etc.)
import 'vehicle_event.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/vehicle_repository.dart';
// FIX: Import constants (defines VehicleFilter enum)
import '../../core/constants.dart';

// --- STATE DEFINITIONS ---

abstract class VehicleState extends Equatable {
  const VehicleState();
  // FIX: Allow nullable objects in props for consistency
  @override
  List<Object?> get props => [];
}

// FIX: Added 'const' to constructors
class VehicleInitial extends VehicleState {
  const VehicleInitial();
}

class VehicleLoading extends VehicleState {}

class VehicleError extends VehicleState {
  final String message;
  const VehicleError(this.message);
  @override
  List<Object?> get props => [message];
}

class VehicleLoaded extends VehicleState {
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;
  final VehicleFilter activeFilter;

  const VehicleLoaded(
    this.vehicles, {
    this.selectedVehicle,
    this.activeFilter = VehicleFilter.all,
  });

  @override
  List<Object?> get props => [vehicles, selectedVehicle, activeFilter];

  VehicleLoaded copyWith({
    VehicleModel? selectedVehicle,
    VehicleFilter? activeFilter,
    List<VehicleModel>? vehicles,
    // Helper to deselect vehicle by passing null explicitly
    bool forceDeselect = false,
  }) {
    return VehicleLoaded(
      vehicles ?? this.vehicles,
      selectedVehicle:
          forceDeselect ? null : selectedVehicle ?? this.selectedVehicle,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

// --- BLOC LOGIC ---

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository _repository;
  Timer? _timer;
  static const int refreshIntervalSeconds = 15; // Auto-refresh interval

  // FIX: Now this line is valid because VehicleInitial is const.
  VehicleBloc(this._repository) : super(const VehicleInitial()) {
    // 1. Event Mappings
    on<VehicleFetchRequested>(_onFetchRequested);
    on<VehicleFilterUpdated>(_onFilterUpdated);
    on<VehicleSelectionUpdated>(_onSelectionUpdated);

    _startAutoRefresh();
    // Add initial fetch
    add(const VehicleFetchRequested(showLoading: true));
  }

  // --- Core Fetch Logic ---
  // THIS IS THE MAIN SYNTAX FIX
  Future<void> _onFetchRequested(
      VehicleFetchRequested event, Emitter<VehicleState> emit) async {
    // For manual fetch, we show loading screen if not already loaded
    if (event.showLoading && state is! VehicleLoaded) {
      emit(VehicleLoading());
    }
    try {
      final vehicleList = await _repository.fetchAllVehicleLocations();

      // Preserve existing filter and selection if already loaded
      final currentState = state is VehicleLoaded ? state as VehicleLoaded : null;

      emit(VehicleLoaded(
        vehicleList,
        selectedVehicle: currentState?.selectedVehicle,
        activeFilter: currentState?.activeFilter ?? VehicleFilter.all,
      ));
    } catch (e) {
      if (state is VehicleLoaded) {
        // Keep existing data on failure to prevent flicker (silent fail)
        // ignore: avoid_print
        print("Auto-refresh failed: $e. Keeping existing map data.");
      } else {
        emit(const VehicleError("Failed to fetch vehicle locations."));
      }
    }
  }

  // --- Event Handlers ---

  void _onFilterUpdated(
      VehicleFilterUpdated event, Emitter<VehicleState> emit) {
    if (state is VehicleLoaded) {
      final loadedState = state as VehicleLoaded;
      if (loadedState.activeFilter != event.filter) {
        // When filter changes, deselect the vehicle
        emit(loadedState.copyWith(
            activeFilter: event.filter, forceDeselect: true));
      }
    }
  }

  void _onSelectionUpdated(
      VehicleSelectionUpdated event, Emitter<VehicleState> emit) {
    if (state is! VehicleLoaded) return;

    final loadedState = state as VehicleLoaded;
    final vehicleId = event.vehicleId;

    VehicleModel? selected;
    if (vehicleId != null) {
      try {
        selected = loadedState.vehicles.firstWhere((v) => v.id == vehicleId);
      } catch (e) {
        // ignore: avoid_print
        print('Vehicle not found for ID: $vehicleId');
      }
    }

    // Use copyWith to handle both selecting (selected) and deselecting (null)
    emit(loadedState.copyWith(
        selectedVehicle: selected, forceDeselect: vehicleId == null));
  }

  // --- Timer Management (Auto-refresh) ---
  void _startAutoRefresh() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: refreshIntervalSeconds),
      (timer) {
        // Only add a new fetch event if the BLoC is not already loading
        if (state is! VehicleLoading) {
          // FIX: Add an event instead of calling the method directly
          add(const VehicleFetchRequested(showLoading: false));
        }
      },
    );
  }

  // 🟢 START FIX: All logic below is simplified

  // Helper to check the *clean* status from the model
  bool _isVehicleRunning(VehicleModel v) {
    return (v.status ?? '').toLowerCase() == 'running';
  }

  // Helper to get the color for the *clean* status
  Color getStatusColor(String? status) {
    final s = (status ?? '').toLowerCase();

    switch (s) {
      case 'running':
        return Colors.green.shade700;
      case 'idle':
        return Colors.orange.shade700;
      case 'parked':
        return Colors.blueGrey;
      case 'no data':
      case 'maintenance':
        return Colors.red;
      default:
        return kPlaceholderColor;
    }
  }

  // Public helper for the UI to get counts based on *clean* data
  int countVehiclesByFilter(VehicleFilter filter) {
    if (state is! VehicleLoaded) return 0;
    final vehicles = (state as VehicleLoaded).vehicles;

    switch (filter) {
      case VehicleFilter.all:
        return vehicles.length;
      case VehicleFilter.running:
        // Uses the simplified helper
        return vehicles.where(_isVehicleRunning).length;
      case VehicleFilter.idle:
        // No aliases needed
        return vehicles
            .where((v) => (v.status ?? '').toLowerCase() == 'idle')
            .length;
      case VehicleFilter.parked:
        // No aliases needed
        return vehicles
            .where((v) => (v.status ?? '').toLowerCase() == 'parked')
            .length;
      case VehicleFilter.noData:
        return vehicles
            .where((v) => (v.status ?? '').toLowerCase() == 'no data')
            .length;
    }
  }
  // 🟢 END FIX

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

