import 'dart:math' as math;
import 'dart:ui';

/// Helpers that translate normalized (0..1) map coordinates into the
/// approximate real-world numbers the demo shows (km, minutes, fare).
class Geo {
  Geo._();

  /// City span the normalized map represents, in km. Used to turn the
  /// 0..1 distance into a believable kilometre figure.
  static const double cityScaleKm = 18.0;
  static const double avgSpeedKmh = 34.0;

  static double distance(Offset a, Offset b) => (a - b).distance;

  static double distanceKm(Offset a, Offset b) => distance(a, b) * cityScaleKm;

  static double etaMinutes(Offset a, Offset b) =>
      (distanceKm(a, b) / avgSpeedKmh) * 60;

  /// Simple, transparent fare model: base + per-km + per-minute, scaled by
  /// the vehicle class multiplier.
  static double estimateFare(double km, double multiplier) {
    const base = 2.5;
    const perKm = 1.15;
    const perMin = 0.25;
    final minutes = (km / avgSpeedKmh) * 60;
    final raw = (base + km * perKm + minutes * perMin) * multiplier;
    return (raw * 100).roundToDouble() / 100;
  }

  static double clamp01(double v) => v.clamp(0.0, 1.0);

  /// Nudges a point toward [target] by [t] (0..1) — used to animate drivers.
  static Offset lerpTowards(Offset from, Offset target, double t) =>
      Offset.lerp(from, target, t) ?? from;

  static double angleBetween(Offset a, Offset b) =>
      math.atan2(b.dy - a.dy, b.dx - a.dx);
}
