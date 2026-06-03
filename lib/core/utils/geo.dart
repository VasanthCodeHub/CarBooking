import 'package:latlong2/latlong.dart';

/// Real-world distance / ETA / fare helpers. Coordinates are true latitude /
/// longitude (matching the Spring Boot backend), so distance is great-circle.
class Geo {
  Geo._();

  static const double avgSpeedKmh = 34.0;
  static const Distance _distance = Distance();

  /// Great-circle distance between two coordinates, in kilometres.
  static double distanceKm(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Kilometer, a, b);

  static double etaMinutes(LatLng a, LatLng b) =>
      distanceKm(a, b) / avgSpeedKmh * 60;

  /// base + per-km + per-minute, scaled by the vehicle class multiplier.
  /// Mirrors the backend's GeoService.estimateFare so previews match.
  static double estimateFare(double km, double multiplier) {
    const base = 2.5;
    const perKm = 1.15;
    const perMin = 0.25;
    final minutes = (km / avgSpeedKmh) * 60;
    final raw = (base + km * perKm + minutes * perMin) * multiplier;
    return (raw * 100).roundToDouble() / 100;
  }

  static double clamp01(double v) => v.clamp(0.0, 1.0);
}
