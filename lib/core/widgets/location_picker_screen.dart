import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/booking.dart';
import '../theme/app_colors.dart';

/// Full-screen map picker built on flutter_map (free OpenStreetMap tiles, no
/// API key). The user pans the map under a fixed center pin and confirms;
/// returns the chosen [Place] via [Navigator.pop].
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.title,
    required this.label,
    required this.initialCenter,
    this.accent = AppColors.primary,
  });

  /// App-bar title, e.g. "Choose pickup".
  final String title;

  /// Label stored on the returned [Place], e.g. "Pickup".
  final String label;

  final LatLng initialCenter;
  final Color accent;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _map = MapController();
  late LatLng _center = widget.initialCenter;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Ask for location permission as soon as the map opens; if granted,
    // center on the user. Deferred so the map is laid out before we move it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      // Try a fresh fix (with a timeout), then fall back to the last known one.
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;
      final here = LatLng(pos.latitude, pos.longitude);
      _map.move(here, 15);
      setState(() => _center = here);
    } catch (_) {
      // Ignore — the user can still pick manually.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final place = Place(
      label: widget.label,
      address:
          '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
      position: _center,
    );
    Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: (camera, _) => _center = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.booking',
                maxZoom: 19,
              ),
            ],
          ),
          // Fixed center pin (sits slightly above true center so the tip points
          // at the map center).
          Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: Icon(Icons.location_on, size: 44, color: widget.accent),
          ),
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton.small(
              heroTag: 'myloc',
              backgroundColor: Colors.white,
              foregroundColor: widget.accent,
              onPressed: _locating ? null : _useMyLocation,
              child: _locating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
            icon: const Icon(Icons.check_rounded),
            label: Text('Set ${widget.label.toLowerCase()} here'),
          ),
        ),
      ),
    );
  }
}
