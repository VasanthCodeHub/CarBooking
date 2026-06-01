import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'vehicle.dart';

/// Lifecycle of a reservation. The dispatch engine moves a booking from
/// [pending] to [assigned]; the driver advances it through the trip states.
enum BookingStatus {
  pending, // created, waiting for auto-dispatch
  assigned, // a driver has been auto-assigned
  enRoute, // driver heading to pickup
  arrived, // driver at pickup
  onTrip, // passenger on board
  completed,
  cancelled;

  String get label => switch (this) {
        BookingStatus.pending => 'Finding driver',
        BookingStatus.assigned => 'Driver assigned',
        BookingStatus.enRoute => 'On the way',
        BookingStatus.arrived => 'Driver arrived',
        BookingStatus.onTrip => 'In progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        BookingStatus.pending => AppColors.amber,
        BookingStatus.assigned => AppColors.info,
        BookingStatus.enRoute => AppColors.info,
        BookingStatus.arrived => AppColors.primary,
        BookingStatus.onTrip => AppColors.primary,
        BookingStatus.completed => AppColors.success,
        BookingStatus.cancelled => AppColors.danger,
      };

  bool get isActive =>
      this == BookingStatus.assigned ||
      this == BookingStatus.enRoute ||
      this == BookingStatus.arrived ||
      this == BookingStatus.onTrip;

  bool get isLive => isActive || this == BookingStatus.pending;
}

/// A named location on the mock map (normalized 0..1 coordinates).
class Place {
  final String label;
  final String address;
  final Offset position;

  const Place({required this.label, required this.address, required this.position});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        label: json['label'] as String,
        address: json['address'] as String,
        position: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
      );

  Map<String, dynamic> toJson() =>
      {'label': label, 'address': address, 'x': position.dx, 'y': position.dy};
}

/// A reservation / ride request.
class Booking {
  final String id;
  final String customerId;
  final String customerName;
  final Place pickup;
  final Place dropoff;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final VehicleType vehicleType;
  final double distanceKm;
  final double fare;
  final BookingStatus status;
  final String? driverId;
  final String? notes;
  final int passengers;

  const Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.pickup,
    required this.dropoff,
    required this.scheduledAt,
    required this.createdAt,
    required this.vehicleType,
    required this.distanceKm,
    required this.fare,
    required this.status,
    this.driverId,
    this.notes,
    this.passengers = 1,
  });

  bool get isScheduled => scheduledAt.difference(createdAt).inMinutes > 20;

  Booking copyWith({
    BookingStatus? status,
    String? driverId,
    double? fare,
  }) =>
      Booking(
        id: id,
        customerId: customerId,
        customerName: customerName,
        pickup: pickup,
        dropoff: dropoff,
        scheduledAt: scheduledAt,
        createdAt: createdAt,
        vehicleType: vehicleType,
        distanceKm: distanceKm,
        fare: fare ?? this.fare,
        status: status ?? this.status,
        driverId: driverId ?? this.driverId,
        notes: notes,
        passengers: passengers,
      );

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        customerId: json['customer_id'].toString(),
        customerName: json['customer_name'] as String,
        pickup: Place.fromJson(json['pickup'] as Map<String, dynamic>),
        dropoff: Place.fromJson(json['dropoff'] as Map<String, dynamic>),
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        vehicleType: VehicleType.fromName(json['vehicle_type'] as String),
        distanceKm: (json['distance_km'] as num).toDouble(),
        fare: (json['fare'] as num).toDouble(),
        status: BookingStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => BookingStatus.pending,
        ),
        driverId: json['driver_id']?.toString(),
        notes: json['notes'] as String?,
        passengers: json['passengers'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'scheduled_at': scheduledAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'vehicle_type': vehicleType.name,
        'distance_km': distanceKm,
        'fare': fare,
        'status': status.name,
        'driver_id': driverId,
        'notes': notes,
        'passengers': passengers,
      };
}
