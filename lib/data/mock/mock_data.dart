import 'dart:ui';

import '../../core/utils/geo.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/driver.dart';
import '../models/user_role.dart';
import '../models/vehicle.dart';

/// All seed data for the POC lives here. When the Python API is ready, the
/// repositories stop reading from this file and hit the network instead.
class MockData {
  MockData._();

  // ---- Demo accounts ---------------------------------------------------
  // Any password works in the POC; pick the role on the login screen.
  static final List<AppUser> users = [
    const AppUser(
      id: 'u_cust_1',
      name: 'Olivia Bennett',
      email: 'customer@demo.com',
      phone: '+1 415 555 0101',
      role: UserRole.customer,
    ),
    const AppUser(
      id: 'u_drv_1',
      name: 'Marcus Reed',
      email: 'driver@demo.com',
      phone: '+1 415 555 0114',
      role: UserRole.driver,
      driverId: 'd1',
    ),
    const AppUser(
      id: 'u_admin_1',
      name: 'Priya Nair',
      email: 'admin@demo.com',
      phone: '+1 415 555 0100',
      role: UserRole.admin,
    ),
  ];

  // ---- Saved places ----------------------------------------------------
  static const Place home = Place(
    label: 'Home',
    address: '120 Marina Blvd',
    position: Offset(0.22, 0.30),
  );
  static const Place office = Place(
    label: 'Office',
    address: '500 Howard St, Suite 12',
    position: Offset(0.70, 0.66),
  );
  static const Place airport = Place(
    label: 'City Airport',
    address: 'Terminal B, Departures',
    position: Offset(0.86, 0.18),
  );
  static const Place mall = Place(
    label: 'Grand Central Mall',
    address: '88 Market Square',
    position: Offset(0.46, 0.50),
  );
  static const Place hotel = Place(
    label: 'Hotel Belmore',
    address: '7 Riverside Walk',
    position: Offset(0.34, 0.74),
  );
  static const Place stadium = Place(
    label: 'North Stadium',
    address: 'Gate 4, North Stadium',
    position: Offset(0.60, 0.22),
  );

  static const List<Place> savedPlaces = [home, office, airport, mall, hotel, stadium];

  // ---- Fleet (5-6 drivers, matching the client's size) -----------------
  static final List<Driver> drivers = [
    Driver(
      id: 'd1',
      name: 'Marcus Reed',
      phone: '+1 415 555 0114',
      rating: 4.9,
      completedTrips: 1284,
      zone: 'Downtown',
      status: DriverStatus.available,
      position: const Offset(0.40, 0.42),
      vehicle: const Vehicle(
        make: 'Toyota',
        model: 'Camry',
        plate: 'KA 09 MA 1284',
        color: 'Silver',
        type: VehicleType.comfort,
      ),
    ),
    Driver(
      id: 'd2',
      name: 'Sofia Marin',
      phone: '+1 415 555 0132',
      rating: 4.8,
      completedTrips: 970,
      zone: 'Marina',
      status: DriverStatus.available,
      position: const Offset(0.26, 0.34),
      vehicle: const Vehicle(
        make: 'Hyundai',
        model: 'Sonata',
        plate: 'KA 05 SM 0970',
        color: 'White',
        type: VehicleType.economy,
      ),
    ),
    Driver(
      id: 'd3',
      name: 'David Okoro',
      phone: '+1 415 555 0148',
      rating: 4.7,
      completedTrips: 1543,
      zone: 'Airport',
      status: DriverStatus.onTrip,
      position: const Offset(0.78, 0.30),
      vehicle: const Vehicle(
        make: 'Kia',
        model: 'Carnival',
        plate: 'KA 41 DO 1543',
        color: 'Black',
        type: VehicleType.suv,
      ),
    ),
    Driver(
      id: 'd4',
      name: 'Elena Petrova',
      phone: '+1 415 555 0156',
      rating: 5.0,
      completedTrips: 642,
      zone: 'Uptown',
      status: DriverStatus.available,
      position: const Offset(0.62, 0.58),
      vehicle: const Vehicle(
        make: 'Mercedes',
        model: 'E-Class',
        plate: 'KA 01 EP 0642',
        color: 'Graphite',
        type: VehicleType.luxury,
      ),
    ),
    Driver(
      id: 'd5',
      name: 'Liam Walsh',
      phone: '+1 415 555 0167',
      rating: 4.6,
      completedTrips: 388,
      zone: 'Riverside',
      status: DriverStatus.available,
      position: const Offset(0.48, 0.72),
      vehicle: const Vehicle(
        make: 'Honda',
        model: 'Accord',
        plate: 'KA 03 LW 0388',
        color: 'Blue',
        type: VehicleType.comfort,
      ),
    ),
    Driver(
      id: 'd6',
      name: 'Aisha Khan',
      phone: '+1 415 555 0179',
      rating: 4.85,
      completedTrips: 1102,
      zone: 'Downtown',
      status: DriverStatus.offline,
      position: const Offset(0.55, 0.46),
      vehicle: const Vehicle(
        make: 'Tesla',
        model: 'Model 3',
        plate: 'KA 07 AK 1102',
        color: 'Pearl',
        type: VehicleType.luxury,
      ),
    ),
  ];

  // ---- Sample bookings -------------------------------------------------
  static List<Booking> seedBookings() {
    final now = DateTime.now();

    Booking make({
      required String id,
      required String customerId,
      required String customerName,
      required Place pickup,
      required Place dropoff,
      required DateTime scheduledAt,
      required DateTime createdAt,
      required VehicleType type,
      required BookingStatus status,
      String? driverId,
      int passengers = 1,
      String? notes,
    }) {
      final km = Geo.distanceKm(pickup.position, dropoff.position);
      return Booking(
        id: id,
        customerId: customerId,
        customerName: customerName,
        pickup: pickup,
        dropoff: dropoff,
        scheduledAt: scheduledAt,
        createdAt: createdAt,
        vehicleType: type,
        distanceKm: km,
        fare: Geo.estimateFare(km, type.fareMultiplier),
        status: status,
        driverId: driverId,
        passengers: passengers,
        notes: notes,
      );
    }

    return [
      make(
        id: 'b1001',
        customerId: 'u_cust_1',
        customerName: 'Olivia Bennett',
        pickup: home,
        dropoff: airport,
        scheduledAt: now.add(const Duration(hours: 3, minutes: 15)),
        createdAt: now.subtract(const Duration(minutes: 40)),
        type: VehicleType.suv,
        status: BookingStatus.assigned,
        driverId: 'd3',
        passengers: 2,
        notes: 'Two large suitcases',
      ),
      make(
        id: 'b1002',
        customerId: 'u_cust_1',
        customerName: 'Olivia Bennett',
        pickup: office,
        dropoff: home,
        scheduledAt: now.add(const Duration(minutes: 12)),
        createdAt: now.subtract(const Duration(minutes: 5)),
        type: VehicleType.comfort,
        status: BookingStatus.enRoute,
        driverId: 'd1',
      ),
      make(
        id: 'b1003',
        customerId: 'u_cust_2',
        customerName: 'Noah Carter',
        pickup: hotel,
        dropoff: stadium,
        scheduledAt: now.add(const Duration(minutes: 6)),
        createdAt: now.subtract(const Duration(minutes: 2)),
        type: VehicleType.economy,
        status: BookingStatus.pending,
      ),
      make(
        id: 'b1004',
        customerId: 'u_cust_3',
        customerName: 'Mia Thompson',
        pickup: mall,
        dropoff: office,
        scheduledAt: now.add(const Duration(days: 1, hours: 2)),
        createdAt: now.subtract(const Duration(hours: 1)),
        type: VehicleType.luxury,
        status: BookingStatus.pending,
        passengers: 3,
      ),
      make(
        id: 'b1005',
        customerId: 'u_cust_1',
        customerName: 'Olivia Bennett',
        pickup: airport,
        dropoff: hotel,
        scheduledAt: now.subtract(const Duration(hours: 20)),
        createdAt: now.subtract(const Duration(hours: 22)),
        type: VehicleType.comfort,
        status: BookingStatus.completed,
        driverId: 'd2',
      ),
      make(
        id: 'b1006',
        customerId: 'u_cust_4',
        customerName: 'Ethan Brooks',
        pickup: stadium,
        dropoff: mall,
        scheduledAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        type: VehicleType.economy,
        status: BookingStatus.completed,
        driverId: 'd5',
      ),
    ];
  }
}
