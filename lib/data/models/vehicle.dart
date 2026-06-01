import 'package:flutter/material.dart';

/// Vehicle classes a customer can request. Fare multipliers feed the estimate.
enum VehicleType {
  economy,
  comfort,
  suv,
  luxury;

  String get label => switch (this) {
        VehicleType.economy => 'Economy',
        VehicleType.comfort => 'Comfort',
        VehicleType.suv => 'SUV',
        VehicleType.luxury => 'Luxury',
      };

  String get description => switch (this) {
        VehicleType.economy => 'Affordable everyday rides',
        VehicleType.comfort => 'Newer cars, extra legroom',
        VehicleType.suv => 'Up to 6 seats, extra luggage',
        VehicleType.luxury => 'Premium cars, top-rated drivers',
      };

  int get seats => switch (this) {
        VehicleType.economy => 4,
        VehicleType.comfort => 4,
        VehicleType.suv => 6,
        VehicleType.luxury => 4,
      };

  double get fareMultiplier => switch (this) {
        VehicleType.economy => 1.0,
        VehicleType.comfort => 1.3,
        VehicleType.suv => 1.6,
        VehicleType.luxury => 2.2,
      };

  IconData get icon => switch (this) {
        VehicleType.economy => Icons.directions_car_filled_rounded,
        VehicleType.comfort => Icons.local_taxi_rounded,
        VehicleType.suv => Icons.airport_shuttle_rounded,
        VehicleType.luxury => Icons.car_rental_rounded,
      };

  static VehicleType fromName(String name) =>
      VehicleType.values.firstWhere((v) => v.name == name, orElse: () => VehicleType.economy);
}

/// A concrete car assigned to a driver.
class Vehicle {
  final String make;
  final String model;
  final String plate;
  final String color;
  final VehicleType type;

  const Vehicle({
    required this.make,
    required this.model,
    required this.plate,
    required this.color,
    required this.type,
  });

  String get displayName => '$make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        make: json['make'] as String,
        model: json['model'] as String,
        plate: json['plate'] as String,
        color: json['color'] as String? ?? '',
        type: VehicleType.fromName(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'plate': plate,
        'color': color,
        'type': type.name,
      };
}
