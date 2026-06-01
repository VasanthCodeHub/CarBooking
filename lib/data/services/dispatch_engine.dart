import '../../core/utils/geo.dart';
import '../models/booking.dart';
import '../models/dispatch.dart';
import '../models/driver.dart';

/// The automated ride-dispatching engine.
///
/// Given a booking and the current fleet, it scores every eligible driver and
/// returns a ranked list plus the winner. The admin board renders this so the
/// client can *see* that dispatch happens automatically, with no manual step.
class DispatchEngine {
  const DispatchEngine();

  /// Weights are intentionally explicit so the rationale is easy to explain.
  static const double _wProximity = 55; // closer driver = faster pickup
  static const double _wRating = 20; // reward better-rated drivers
  static const double _wExperience = 10; // tie-break on completed trips
  static const double _wVehicleMatch = 15; // exact class match preferred

  DispatchResult evaluate(Booking booking, List<Driver> fleet) {
    final eligible = fleet.where((d) => d.status == DriverStatus.available).toList();

    final candidates = eligible.map((d) {
      final dist = Geo.distance(d.position, booking.pickup.position);
      final eta = Geo.etaMinutes(d.position, booking.pickup.position);

      // Proximity: nearest of the eligible set scores highest.
      final proximityScore = (1 - Geo.clamp01(dist / 1.0)) * _wProximity;
      final ratingScore = (d.rating / 5.0) * _wRating;
      final expScore = (Geo.clamp01(d.completedTrips / 1500)) * _wExperience;
      final exactMatch = d.vehicle.type == booking.vehicleType;
      final vehicleScore = exactMatch
          ? _wVehicleMatch
          : (d.vehicle.type.seats >= booking.passengers ? _wVehicleMatch * 0.4 : 0);

      final score = proximityScore + ratingScore + expScore + vehicleScore;

      final reasons = <String>[
        '${eta.toStringAsFixed(0)} min away (${Geo.distanceKm(d.position, booking.pickup.position).toStringAsFixed(1)} km)',
        '${d.rating.toStringAsFixed(1)}★ rating',
        if (exactMatch)
          '${d.vehicle.type.label} matches request'
        else if (d.vehicle.type.seats >= booking.passengers)
          'Fits ${booking.passengers} passenger(s)',
        '${d.completedTrips} trips completed',
      ];

      return DispatchCandidate(
        driver: d,
        score: score.toDouble(),
        distanceToPickup: dist,
        etaMinutes: eta,
        reasons: reasons,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return DispatchResult(
      bookingId: booking.id,
      winner: candidates.isEmpty ? null : candidates.first,
      ranked: candidates,
    );
  }
}
