import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a driver's live GPS position as stored in Firestore.
class DriverLocationModel {
  final double latitude;
  final double longitude;
  final String driverEmail;
  final String? routeId;
  final DateTime? timestamp;

  DriverLocationModel({
    required this.latitude,
    required this.longitude,
    required this.driverEmail,
    this.routeId,
    this.timestamp,
  });

  factory DriverLocationModel.fromMap(Map<String, dynamic> map) {
    return DriverLocationModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      driverEmail: map['driverEmail'] ?? '',
      routeId: map['routeId'],
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'driverEmail': driverEmail,
      'routeId': routeId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
