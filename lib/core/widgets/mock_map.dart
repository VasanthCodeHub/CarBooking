import 'dart:math' as math;

import 'package:flutter/material.dart';
// latlong2 also exports a `Path` type; hide it so dart:ui's Path wins.
import 'package:latlong2/latlong.dart' hide Path;

import '../theme/app_colors.dart';

/// A driver marker drawn on the [MockMap].
class MapDriver {
  final LatLng position;
  final Color color;
  final String? label;
  final bool highlighted;

  const MapDriver({
    required this.position,
    this.color = AppColors.driver,
    this.label,
    this.highlighted = false,
  });
}

/// A stylized, dependency-free map used for inline previews (trip detail, fleet
/// overview, etc). It takes real [LatLng] coordinates and projects them onto a
/// fitted bounding box so the layout looks sensible without loading map tiles.
/// For interactive picking we use a real [flutter_map] instead.
class MockMap extends StatelessWidget {
  const MockMap({
    super.key,
    this.pickup,
    this.dropoff,
    this.drivers = const [],
    this.routeProgress,
    this.showRoute = true,
    this.height = 220,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(0),
  });

  final LatLng? pickup;
  final LatLng? dropoff;
  final List<MapDriver> drivers;

  /// If set (0..1), draws a car travelling along the route at this progress.
  final double? routeProgress;
  final bool showRoute;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _MapPainter(
              pickup: pickup,
              dropoff: dropoff,
              drivers: drivers,
              routeProgress: routeProgress,
              showRoute: showRoute,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.pickup,
    required this.dropoff,
    required this.drivers,
    required this.routeProgress,
    required this.showRoute,
  }) {
    // Fit a bounding box around every point so the projection is stable.
    final pts = <LatLng>[
      if (pickup != null) pickup!,
      if (dropoff != null) dropoff!,
      ...drivers.map((d) => d.position),
    ];
    if (pts.isEmpty) {
      _minLat = 0;
      _maxLat = 1;
      _minLng = 0;
      _maxLng = 1;
    } else {
      _minLat = pts.map((p) => p.latitude).reduce(math.min);
      _maxLat = pts.map((p) => p.latitude).reduce(math.max);
      _minLng = pts.map((p) => p.longitude).reduce(math.min);
      _maxLng = pts.map((p) => p.longitude).reduce(math.max);
    }
  }

  final LatLng? pickup;
  final LatLng? dropoff;
  final List<MapDriver> drivers;
  final double? routeProgress;
  final bool showRoute;

  late final double _minLat, _maxLat, _minLng, _maxLng;
  static const double _margin = 0.14; // keep points off the edges

  /// Projects a real coordinate into screen space within the fitted box.
  Offset _p(LatLng c, Size s) {
    const eps = 1e-6;
    final lngSpan = math.max(_maxLng - _minLng, eps);
    final latSpan = math.max(_maxLat - _minLat, eps);
    final fx = (_maxLng - _minLng) < eps ? 0.5 : (c.longitude - _minLng) / lngSpan;
    final fy = (_maxLat - _minLat) < eps ? 0.5 : (_maxLat - c.latitude) / latSpan;
    final x = (_margin + fx * (1 - 2 * _margin)) * s.width;
    final y = (_margin + fy * (1 - 2 * _margin)) * s.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEAF0F8), Color(0xFFDCE6F2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawBlocks(canvas, size);
    _drawRoads(canvas, size);

    if (showRoute && pickup != null && dropoff != null) {
      _drawRoute(canvas, size, _p(pickup!, size), _p(dropoff!, size));
    }

    for (final d in drivers) {
      _drawCar(canvas, _p(d.position, size), d.color, d.highlighted);
    }

    if (routeProgress != null && pickup != null && dropoff != null) {
      final pos = Offset.lerp(_p(pickup!, size), _p(dropoff!, size), routeProgress!)!;
      _drawCar(canvas, pos, AppColors.primary, true);
    }

    if (pickup != null) _drawPin(canvas, _p(pickup!, size), AppColors.success, true);
    if (dropoff != null) _drawPin(canvas, _p(dropoff!, size), AppColors.danger, false);
  }

  void _drawBlocks(Canvas canvas, Size size) {
    final block = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final rnd = math.Random(7);
    for (int i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final w = 22 + rnd.nextDouble() * 46;
      final h = 18 + rnd.nextDouble() * 40;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, block);
    }
  }

  void _drawRoads(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    for (double x = size.width * 0.2; x < size.width; x += size.width * 0.28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (double y = size.height * 0.25; y < size.height; y += size.height * 0.3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
  }

  void _drawRoute(Canvas canvas, Size size, Offset a, Offset b) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, a.dy)
      ..lineTo(b.dx, b.dy);

    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glow);

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);
  }

  void _drawPin(Canvas canvas, Offset c, Color color, bool isStart) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawCircle(c.translate(0, 2), 13, shadow);

    final ring = Paint()..color = Colors.white;
    canvas.drawCircle(c, 12, ring);
    final dot = Paint()..color = color;
    canvas.drawCircle(c, 8, dot);
    final inner = Paint()..color = Colors.white;
    canvas.drawCircle(c, 3, inner);
  }

  void _drawCar(Canvas canvas, Offset c, Color color, bool highlighted) {
    if (highlighted) {
      final halo = Paint()..color = color.withValues(alpha: 0.18);
      canvas.drawCircle(c, 16, halo);
    }
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, 2), width: 22, height: 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(r, shadow);

    final body = Paint()..color = color;
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 22, height: 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(rr, body);

    final icon = Icons.local_taxi_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 14,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.pickup != pickup ||
      old.dropoff != dropoff ||
      old.routeProgress != routeProgress ||
      old.drivers != drivers;
}
