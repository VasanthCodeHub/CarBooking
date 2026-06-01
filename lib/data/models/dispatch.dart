import 'driver.dart';

/// One driver's score for a given booking, with a human-readable rationale
/// the admin dispatch board can show to explain the automatic match.
class DispatchCandidate {
  final Driver driver;
  final double score; // 0..100, higher is better
  final double distanceToPickup; // normalized map units
  final double etaMinutes;
  final List<String> reasons;

  const DispatchCandidate({
    required this.driver,
    required this.score,
    required this.distanceToPickup,
    required this.etaMinutes,
    required this.reasons,
  });
}

/// The outcome of running the auto-dispatch engine for a booking.
class DispatchResult {
  final String bookingId;
  final DispatchCandidate? winner;
  final List<DispatchCandidate> ranked;

  const DispatchResult({
    required this.bookingId,
    required this.winner,
    required this.ranked,
  });

  bool get matched => winner != null;
}
