import '../../core/utils/geo.dart';
import '../mock/mock_data.dart';
import '../models/booking.dart';
import '../models/dispatch.dart';
import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/dispatch_engine.dart';
import 'driver_repository.dart';

/// Stores reservations and runs the auto-dispatch engine when one is created.
abstract class BookingRepository {
  Future<List<Booking>> getAll();
  Future<List<Booking>> forCustomer(String customerId);
  Future<List<Booking>> forDriver(String driverId);
  Future<Booking?> getById(String id);

  /// Creates a reservation and immediately auto-assigns the best driver.
  Future<DispatchResult> createAndDispatch(Booking draft);

  /// Re-run matching for a still-pending booking (admin "dispatch now").
  Future<DispatchResult> redispatch(String bookingId);

  DispatchResult previewDispatch(Booking booking);

  Future<Booking> advanceStatus(String bookingId, BookingStatus status);
  Future<Booking> cancel(String bookingId);
  List<Booking> get current;
}

class MockBookingRepository implements BookingRepository {
  MockBookingRepository(this._driverRepo);

  final DriverRepository _driverRepo;
  final DispatchEngine _engine = const DispatchEngine();
  final List<Booking> _bookings = MockData.seedBookings();

  @override
  List<Booking> get current => List.unmodifiable(_bookings);

  @override
  Future<List<Booking>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sorted(_bookings);
  }

  @override
  Future<List<Booking>> forCustomer(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sorted(_bookings.where((b) => b.customerId == customerId).toList());
  }

  @override
  Future<List<Booking>> forDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sorted(_bookings.where((b) => b.driverId == driverId).toList());
  }

  @override
  Future<Booking?> getById(String id) async {
    final i = _bookings.indexWhere((b) => b.id == id);
    return i == -1 ? null : _bookings[i];
  }

  @override
  DispatchResult previewDispatch(Booking booking) =>
      _engine.evaluate(booking, _driverRepo.current);

  @override
  Future<DispatchResult> createAndDispatch(Booking draft) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final result = _engine.evaluate(draft, _driverRepo.current);
    final assigned = draft.copyWith(
      status: result.matched ? BookingStatus.assigned : BookingStatus.pending,
      driverId: result.winner?.driver.id,
    );
    _bookings.insert(0, assigned);
    if (result.matched) {
      await _driverRepo.setStatus(result.winner!.driver.id, DriverStatus.onTrip);
    }
    return DispatchResult(
      bookingId: assigned.id,
      winner: result.winner,
      ranked: result.ranked,
    );
  }

  @override
  Future<DispatchResult> redispatch(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i == -1) throw StateError('Booking $bookingId not found');
    final result = _engine.evaluate(_bookings[i], _driverRepo.current);
    if (result.matched) {
      _bookings[i] = _bookings[i].copyWith(
        status: BookingStatus.assigned,
        driverId: result.winner!.driver.id,
      );
      await _driverRepo.setStatus(result.winner!.driver.id, DriverStatus.onTrip);
    }
    return result;
  }

  @override
  Future<Booking> advanceStatus(String bookingId, BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i == -1) throw StateError('Booking $bookingId not found');
    _bookings[i] = _bookings[i].copyWith(status: status);

    // Free the driver again once the trip ends.
    final driverId = _bookings[i].driverId;
    if (driverId != null &&
        (status == BookingStatus.completed || status == BookingStatus.cancelled)) {
      await _driverRepo.setStatus(driverId, DriverStatus.available);
    }
    return _bookings[i];
  }

  @override
  Future<Booking> cancel(String bookingId) =>
      advanceStatus(bookingId, BookingStatus.cancelled);

  List<Booking> _sorted(List<Booking> list) {
    final copy = [...list];
    copy.sort((a, b) {
      // Live first, then by scheduled time.
      final aLive = a.status.isLive ? 0 : 1;
      final bLive = b.status.isLive ? 0 : 1;
      if (aLive != bLive) return aLive - bLive;
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
    return copy;
  }

  /// Builds a draft booking with computed distance + fare from a request.
  static Booking draftFrom({
    required String id,
    required String customerId,
    required String customerName,
    required Place pickup,
    required Place dropoff,
    required DateTime scheduledAt,
    required VehicleType type,
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
      createdAt: DateTime.now(),
      vehicleType: type,
      distanceKm: km,
      fare: Geo.estimateFare(km, type.fareMultiplier),
      status: BookingStatus.pending,
      passengers: passengers,
      notes: notes,
    );
  }
}
