/// Represents a route with its associated trip stops.
class RouteModel {
  final String routeId;
  final String routeName;
  final Map<String, List<RouteStop>> trips; // e.g. { "Trip 1": [...], "Trip 2": [...] }

  RouteModel({
    required this.routeId,
    required this.routeName,
    required this.trips,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final tripsRaw = map['trips'] as Map<String, dynamic>? ?? {};
    final Map<String, List<RouteStop>> parsedTrips = {};

    tripsRaw.forEach((tripName, stops) {
      if (stops is List) {
        parsedTrips[tripName] = stops
            .whereType<Map<String, dynamic>>()
            .map((s) => RouteStop.fromMap(s))
            .toList();
      }
    });

    return RouteModel(
      routeId: docId ?? map['routeId'] ?? '',
      routeName: map['route'] ?? map['routeName'] ?? '',
      trips: parsedTrips,
    );
  }
}

/// A single stop on a route.
class RouteStop {
  final String stop;
  final String timing;
  final String coordinates; // raw "lat,lng" string from Firestore
  final String? tripType;

  RouteStop({
    required this.stop,
    required this.timing,
    required this.coordinates,
    this.tripType,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      stop: map['stop'] ?? 'Unknown Stop',
      timing: map['timing'] ?? '',
      coordinates: map['coordinates'] ?? '',
      tripType: map['tripType'],
    );
  }

  /// Parse the raw coordinate string into lat/lng doubles.
  /// Returns null if parsing fails.
  ({double lat, double lng})? get parsedCoordinates {
    final clean = coordinates.replaceAll(RegExp(r'[^\d.,-]'), '');
    final parts = clean.split(',');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }
}
