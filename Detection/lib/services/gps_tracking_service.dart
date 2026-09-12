import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Centralized GPS tracking service.
///
/// Replaces the Timer.periodic + getCurrentPosition pattern that was
/// previously embedded in driver_dashboard_screen.dart.
/// Uses getPositionStream with distanceFilter so updates only fire
/// when the bus actually moves — far more battery-efficient.
class GpsTrackingService {
  StreamSubscription<Position>? _positionStream;
  Position? lastKnownPosition;

  // ---------------------------------------------------------------
  // Central permission check — call before any GPS operation
  // ---------------------------------------------------------------
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ---------------------------------------------------------------
  // Driver broadcasting — pushes position to Firestore
  // ---------------------------------------------------------------
  void startTracking({
    required String driverEmail,
    required String routeId,
    void Function(Position)? onPositionUpdate,
  }) {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres moved before a new event fires
      ),
    ).listen((Position position) {
      lastKnownPosition = position;

      // Push to Firestore
      FirebaseFirestore.instance
          .collection('driver_locations')
          .doc(driverEmail)
          .set({
        'driverEmail': driverEmail,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'routeId': routeId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notify caller so the UI can update markers / camera
      onPositionUpdate?.call(position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // ---------------------------------------------------------------
  // Student self-location — one-shot fetch via Geolocator
  // (replaces the `location` package usage)
  // ---------------------------------------------------------------
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ---------------------------------------------------------------
  // Student self-location — continuous stream via Geolocator
  // (replaces location.onLocationChanged)
  // ---------------------------------------------------------------
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  void dispose() {
    stopTracking();
  }
}
