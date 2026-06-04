import 'dart:async';

import 'package:dio/dio.dart';
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
  final Dio _geocoder = Dio();
  late LatLng _center = widget.initialCenter;
  bool _locating = false;

  // Live reverse-geocoded place under the center pin.
  String? _placeName;
  String? _placeAddress;
  bool _resolving = false;
  Timer? _debounce;
  int _geoSeq = 0; // guards against out-of-order responses

  @override
  void initState() {
    super.initState();
    // Ask for location permission as soon as the map opens; if granted,
    // center on the user. Deferred so the map is laid out before we move it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _useMyLocation();
      _resolveCenter();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounced reverse geocode whenever the map settles on a new center.
  void _onCenterChanged(LatLng center) {
    _center = center;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _resolveCenter);
  }

  /// Looks up a human-readable place name + address for the current center
  /// using OpenStreetMap's free Nominatim reverse-geocoding service.
  Future<void> _resolveCenter() async {
    final seq = ++_geoSeq;
    final target = _center;
    setState(() => _resolving = true);
    try {
      final res = await _geocoder.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': target.latitude,
          'lon': target.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'com.example.booking (demo)'}),
      );
      if (seq != _geoSeq || !mounted) return; // a newer request superseded us
      final data = res.data as Map<String, dynamic>;
      final display = (data['display_name'] as String?)?.trim();
      final name = (data['name'] as String?)?.trim();
      setState(() {
        _placeName = (name != null && name.isNotEmpty)
            ? name
            : display?.split(',').first.trim();
        _placeAddress = display;
        _resolving = false;
      });
    } catch (_) {
      if (seq != _geoSeq || !mounted) return;
      setState(() => _resolving = false);
    }
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
      _resolveCenter();
    } catch (_) {
      // Ignore — the user can still pick manually.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String get _coords =>
      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';

  void _confirm() {
    final place = Place(
      // Show the real selected place, not the generic "Pickup"/"Drop-off" tag.
      label: (_placeName != null && _placeName!.isNotEmpty)
          ? _placeName!
          : 'Pinned location',
      address: _placeAddress ?? _coords,
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
              onPositionChanged: (camera, _) => _onCenterChanged(camera.center),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AddressPreview(
              accent: widget.accent,
              resolving: _resolving,
              name: _placeName,
              address: _placeAddress ?? _coords,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
                icon: const Icon(Icons.check_rounded),
                label: Text('Set ${widget.label.toLowerCase()} here'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The address card under the confirm button showing what the center pin is
/// currently sitting on while reverse geocoding resolves.
class _AddressPreview extends StatelessWidget {
  const _AddressPreview({
    required this.accent,
    required this.resolving,
    required this.name,
    required this.address,
  });

  final Color accent;
  final bool resolving;
  final String? name;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.place_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolving
                      ? 'Locating…'
                      : (name != null && name!.isNotEmpty
                          ? name!
                          : 'Pinned location'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
