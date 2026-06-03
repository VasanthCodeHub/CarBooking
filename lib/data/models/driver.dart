import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import 'vehicle.dart';

/// Driver availability state used by the dispatch engine.
enum DriverStatus {
  available,
  onTrip,
  offline;

  String get label => switch (this) {
        DriverStatus.available => 'Available',
        DriverStatus.onTrip => 'On trip',
        DriverStatus.offline => 'Offline',
      };

  Color get color => switch (this) {
        DriverStatus.available => AppColors.success,
        DriverStatus.onTrip => AppColors.info,
        DriverStatus.offline => AppColors.inkSoft,
      };
}

/// A fleet driver. Position is a normalized 0..1 coordinate on the mock map.
class Driver {
  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;
  final Vehicle vehicle;
  final double rating;
  final int completedTrips;
  final String zone;
  final DriverStatus status;
  final LatLng position; // real-world coordinate

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
    required this.completedTrips,
    required this.zone,
    required this.status,
    required this.position,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Driver copyWith({
    DriverStatus? status,
    LatLng? position,
    int? completedTrips,
    double? rating,
  }) =>
      Driver(
        id: id,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
        vehicle: vehicle,
        rating: rating ?? this.rating,
        completedTrips: completedTrips ?? this.completedTrips,
        zone: zone,
        status: status ?? this.status,
        position: position ?? this.position,
      );

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'].toString(),
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
        rating: (json['rating'] as num).toDouble(),
        completedTrips: json['completed_trips'] as int? ?? 0,
        zone: json['zone'] as String? ?? '',
        status: DriverStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DriverStatus.offline,
        ),
        position: LatLng(
          (json['lat'] as num?)?.toDouble() ?? 0.0,
          (json['lng'] as num?)?.toDouble() ?? 0.0,
        ),
      );
}
