import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/geo.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/dispatch.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'customer_bookings_viewmodel.dart';

/// Draft state for the multi-step booking flow.
@immutable
class BookRideState {
  final Place? pickup;
  final Place? dropoff;
  final VehicleType vehicleType;
  final bool scheduleLater;
  final DateTime scheduledAt;
  final int passengers;
  final String notes;
  final bool submitting;
  final DispatchResult? result;
  final String? error;

  BookRideState({
    this.pickup,
    this.dropoff,
    this.vehicleType = VehicleType.economy,
    this.scheduleLater = false,
    DateTime? scheduledAt,
    this.passengers = 1,
    this.notes = '',
    this.submitting = false,
    this.result,
    this.error,
  }) : scheduledAt =
            scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));

  bool get hasRoute => pickup != null && dropoff != null;

  double get distanceKm =>
      hasRoute ? Geo.distanceKm(pickup!.position, dropoff!.position) : 0;

  double get fare =>
      hasRoute ? Geo.estimateFare(distanceKm, vehicleType.fareMultiplier) : 0;

  double get etaMinutes =>
      hasRoute ? Geo.etaMinutes(pickup!.position, dropoff!.position) : 0;

  BookRideState copyWith({
    Place? pickup,
    Place? dropoff,
    VehicleType? vehicleType,
    bool? scheduleLater,
    DateTime? scheduledAt,
    int? passengers,
    String? notes,
    bool? submitting,
    DispatchResult? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) =>
      BookRideState(
        pickup: pickup ?? this.pickup,
        dropoff: dropoff ?? this.dropoff,
        vehicleType: vehicleType ?? this.vehicleType,
        scheduleLater: scheduleLater ?? this.scheduleLater,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        passengers: passengers ?? this.passengers,
        notes: notes ?? this.notes,
        submitting: submitting ?? this.submitting,
        result: clearResult ? null : (result ?? this.result),
        error: clearError ? null : (error ?? this.error),
      );
}

/// MVVM ViewModel for creating a reservation and triggering auto-dispatch.
class BookRideViewModel extends AutoDisposeNotifier<BookRideState> {
  @override
  BookRideState build() => BookRideState();

  void setPickup(Place p) => state = state.copyWith(pickup: p, clearResult: true);
  void setDropoff(Place p) => state = state.copyWith(dropoff: p, clearResult: true);

  void swap() {
    if (!state.hasRoute) return;
    state = state.copyWith(
      pickup: state.dropoff,
      dropoff: state.pickup,
      clearResult: true,
    );
  }

  void setVehicle(VehicleType v) => state = state.copyWith(vehicleType: v);
  void setPassengers(int n) =>
      state = state.copyWith(passengers: n.clamp(1, 6));
  void setNotes(String n) => state = state.copyWith(notes: n);

  void setScheduleLater(bool later) {
    state = state.copyWith(
      scheduleLater: later,
      scheduledAt: later
          ? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  void setScheduledAt(DateTime dt) => state = state.copyWith(scheduledAt: dt);

  Future<DispatchResult?> submit() async {
    if (!state.hasRoute) {
      state = state.copyWith(error: 'Choose a pickup and drop-off first.');
      return null;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final draft = _draft('b${DateTime.now().millisecondsSinceEpoch}');
      final result =
          await ref.read(bookingRepositoryProvider).createAndDispatch(draft);
      state = state.copyWith(submitting: false, result: result);
      ref.invalidate(customerBookingsProvider);
      return result;
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        error: 'Could not create the booking. Try again.',
      );
      return null;
    }
  }

  Booking _draft(String id) {
    final user = ref.read(authViewModelProvider).user;
    return MockBookingRepository.draftFrom(
      id: id,
      customerId: user?.id ?? 'guest',
      customerName: user?.name ?? 'Guest',
      pickup: state.pickup!,
      dropoff: state.dropoff!,
      scheduledAt: state.scheduledAt,
      type: state.vehicleType,
      passengers: state.passengers,
      notes: state.notes.isEmpty ? null : state.notes,
    );
  }
}

final bookRideProvider =
    AutoDisposeNotifierProvider<BookRideViewModel, BookRideState>(
        BookRideViewModel.new);
