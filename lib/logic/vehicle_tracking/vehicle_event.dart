import 'package:equatable/equatable.dart';
// 🟢 FIX: Import the VehicleFilter enum from constants.dart
import '../../core/constants.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  // FIX: Allowing nullable objects in props for consistency (VehicleSelectionUpdated uses String?)
  @override
  List<Object?> get props => [];
}

// Event triggered to request fetching the vehicle list from the API
class VehicleFetchRequested extends VehicleEvent {
  // FIX: Add showLoading property
  final bool showLoading;
  const VehicleFetchRequested({this.showLoading = false});

  @override
  List<Object?> get props => [showLoading];
}

// Event triggered when the user wants to filter the displayed vehicles
class VehicleFilterUpdated extends VehicleEvent {
  final VehicleFilter filter;
  const VehicleFilterUpdated(this.filter);

  @override
  List<Object?> get props => [filter];
}

// Event triggered when a user taps a marker to select a vehicle
class VehicleSelectionUpdated extends VehicleEvent {
  final String? vehicleId;
  const VehicleSelectionUpdated(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

