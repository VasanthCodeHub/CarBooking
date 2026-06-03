import 'driver.dart';

/// One driver's score for a given booking, with a human-readable rationale
/// the admin dispatch board can show to explain the automatic match.
class DispatchCandidate {
  final Driver driver;
  final double score; // 0..100, higher is better
  final double distanceKm; // distance from driver to pickup
  final double etaMinutes;
  final List<String> reasons;

  const DispatchCandidate({
    required this.driver,
    required this.score,
    required this.distanceKm,
    required this.etaMinutes,
    required this.reasons,
  });

  factory DispatchCandidate.fromJson(Map<String, dynamic> json) =>
      DispatchCandidate(
        driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
        score: (json['score'] as num).toDouble(),
        distanceKm: (json['distance_km'] as num).toDouble(),
        etaMinutes: (json['eta_minutes'] as num).toDouble(),
        reasons: (json['reasons'] as List).map((e) => e.toString()).toList(),
      );
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

  factory DispatchResult.fromJson(Map<String, dynamic> json) => DispatchResult(
        bookingId: json['booking_id'].toString(),
        winner: json['winner'] == null
            ? null
            : DispatchCandidate.fromJson(json['winner'] as Map<String, dynamic>),
        ranked: (json['ranked'] as List? ?? [])
            .map((e) => DispatchCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
