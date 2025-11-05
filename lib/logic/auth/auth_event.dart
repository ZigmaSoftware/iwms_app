// lib/logic/auth/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCitizenLoginRequested extends AuthEvent {
  final String phone;

  const AuthCitizenLoginRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class AuthCitizenRegisterRequested extends AuthEvent {
  final String phone;
  final String ownerName;
  final String contactNo;
  final String buildingNo;
  final String street;
  final String area;
  final String pincode;
  final String city;
  final String district;
  final String state;
  final String zone;
  final String ward;
  final String propertyName;

  const AuthCitizenRegisterRequested({
    required this.phone,
    required this.ownerName,
    required this.contactNo,
    required this.buildingNo,
    required this.street,
    required this.area,
    required this.pincode,
    required this.city,
    required this.district,
    required this.state,
    required this.zone,
    required this.ward,
    required this.propertyName,
  });

  @override
  List<Object?> get props => [
        phone,
        ownerName,
        contactNo,
        buildingNo,
        street,
        area,
        pincode,
        city,
        district,
        state,
        zone,
        ward,
        propertyName,
      ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthStatusChecked extends AuthEvent {}
