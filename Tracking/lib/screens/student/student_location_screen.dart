import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';


class StudentLocationScreen extends StatefulWidget {
  const StudentLocationScreen({super.key});

  @override
  _StudentLocationScreenState createState() => _StudentLocationScreenState();
}

class _StudentLocationScreenState extends State<StudentLocationScreen> {
  late Future<List<Map<String, dynamic>>> assignedBuses;
  String? studentAssignedRoute; // Added to store student's route
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _driverLocationSubscription;
  StreamSubscription<Position>? _userLocationSubscription;
  LatLng? _currentDriverLocation;
  LatLng? _currentUserLocation;
  bool _didLogInitialLayout = false;
  bool _didLogBusData = false;

  void _debugLog({
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
    String runId = 'run1',
  }) {
    try {
      final payload = {
        'sessionId': 'e8ec0b',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      // #region agent log
      File('/Users/haripreeth/Documents/MINI_PROJECT/.cursor/debug-e8ec0b.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append, flush: true);
      debugPrint('DBG_E8EC0B:${jsonEncode(payload)}');
      // #endregion
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    assignedBuses = _initializeData(); // Changed to a combined initialization
    _requestLocationPermission();
    _startUserLocationTracking();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _userLocationSubscription?.cancel();
    super.dispose();
  }

  /// Request location permissions from the user
  Future<void> _requestLocationPermission() async {
    var permissionStatus = await Geolocator.checkPermission();
    if (permissionStatus == LocationPermission.denied) {
      permissionStatus = await Geolocator.requestPermission();
      if (permissionStatus == LocationPermission.denied ||
          permissionStatus == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }
    }

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services must be enabled.')),
      );
      return;
    }
  }

  /// Start tracking the user's live location
  void _startUserLocationTracking() {
    _userLocationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final userPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentUserLocation = userPosition;

        // Remove the previous marker and add a new marker for the user's location
        _markers.removeWhere((marker) => marker.markerId.value == 'userLocation');
        _markers.add(
          Marker(
            markerId: const MarkerId('userLocation'),
            position: userPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Driver Live Location'),
          ),
        );
      });

      // Move the map camera to focus on the user's location
      _mapController?.animateCamera(CameraUpdate.newLatLng(userPosition));
    });
  }

  Future<List<Map<String, dynamic>>> _initializeData() async {
    await _fetchStudentRoute();
    return fetchAssignedBuses();
  }

  Future<void> _fetchStudentRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        if (studentDoc.exists) {
          setState(() {
            studentAssignedRoute = studentDoc.data()?['assignedRoute'];
          });
        }
      }
    } catch (e) {
      print("Error fetching student route: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssignedBuses() async {
    try {
      Query query = FirebaseFirestore.instance.collection('assignments');
      
      // Filter by student's assigned route if available
      if (studentAssignedRoute != null && studentAssignedRoute!.isNotEmpty) {
        query = query.where('routeName', isEqualTo: studentAssignedRoute);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> busList = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final busNumber = data['busNumber'] ?? 'Unknown Bus';
          final routeName = data['routeName'] ?? 'Unknown Route';
          final driverEmail = data['driverEmail'] ?? 'Unknown Email';

          final routeSnapshot = await FirebaseFirestore.instance
              .collection('routes')
              .where('route', isEqualTo: routeName)
              .get();

          if (routeSnapshot.docs.isNotEmpty) {
            final routeData = routeSnapshot.docs.first.data();
            final trips = routeData['trips'] ?? {};

            busList.add({
              'busNumber': busNumber,
              'routeName': routeName,
              'driverEmail': driverEmail,
              'trips': trips,
            });
          }
        }

        // AUTO-TRACK: If there is exactly one bus assigned, start tracking it immediately
        if (busList.length == 1 && mounted) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
            _startDriverLocationTracking(busList[0]['driverEmail']);
            _fetchRouteDetails(busList[0]['routeName']);
          });
        }

        return busList;
      }
      return [];
    } catch (e) {
      print("Error fetching assignments: $e");
      return [];
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Start tracking the live location of a driver from the Firestore database
  void _startDriverLocationTracking(String driverEmail) {
    // Cancel any existing location subscription
    _driverLocationSubscription?.cancel();

    // Clear old markers and polylines before adding new ones
    setState(() {
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value == 'driverLocation');
      _currentDriverLocation = null;
    });

    // Listen to the driver's live location updates
    _driverLocationSubscription = FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(driverEmail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final lat = data['latitude'] ?? 0.0;
          final lng = data['longitude'] ?? 0.0;

          final driverPosition = LatLng(lat, lng);

          setState(() {
            _currentDriverLocation = driverPosition;

            // Remove the previous marker and add a new marker for the driver
            _markers.add(
              Marker(
                markerId: const MarkerId('driverLocation'),
                position: driverPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: 'Driver Location'),
              ),
            );
          });

          // Move the map camera to focus on the driver's location
          _mapController?.animateCamera(CameraUpdate.newLatLng(driverPosition));
        }
      }
    });
  }

  void _fetchRouteDetails(String routeName) async {
    // Clear old markers and polylines before fetching new route details
    setState(() {
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value != 'userLocation' && marker.markerId.value != 'driverLocation');
    });

    final routeSnapshot = await FirebaseFirestore.instance
        .collection('routes')
        .where('route', isEqualTo: routeName)
        .get();

    if (routeSnapshot.docs.isNotEmpty) {
      final routeData = routeSnapshot.docs.first.data();
      final trips = routeData['trips'] ?? {};
      List<LatLng> polylinePoints = [];

      trips.forEach((_, stops) {
        if (stops is List<dynamic>) {
          for (var stop in stops) {
            if (stop is Map<String, dynamic>) {
              final coordinates = stop['coordinates'] as String? ?? '';
              final cleanCoordinates = coordinates.replaceAll(RegExp(r'[^\d.,-]'), '');
              final splitCoordinates = cleanCoordinates.split(',');
              if (splitCoordinates.length >= 2) {
                final lat = double.tryParse(splitCoordinates[0].trim()) ?? 0.0;
                final lng = double.tryParse(splitCoordinates[1].trim()) ?? 0.0;
                
                if (lat != 0.0 || lng != 0.0) {
                  polylinePoints.add(LatLng(lat, lng));

                  _markers.add(
                    Marker(
                      markerId: MarkerId(stop['stop'] ?? 'Unknown Stop'),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(
                        title: stop['stop'] ?? 'Unknown Stop',
                        snippet: 'Time: ${stop['timing'] ?? 'Unknown Time'}',
                      ),
                    ),
                  );
                }
              }
            }
          }
        }
      });

      setState(() {
        _polylines.add(Polyline(
          polylineId: PolylineId(routeName),
          points: polylinePoints,
          color: Colors.blue,
          width: 4,
        ));
      });

      if (polylinePoints.isNotEmpty) {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: polylinePoints.reduce((a, b) => LatLng(
              a.latitude < b.latitude ? a.latitude : b.latitude,
              a.longitude < b.longitude ? a.longitude : b.longitude,
            )),
            northeast: polylinePoints.reduce((a, b) => LatLng(
              a.latitude > b.latitude ? a.latitude : b.latitude,
              a.longitude > b.longitude ? a.longitude : b.longitude,
            )),
          ),
          50,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!_didLogInitialLayout) {
      _didLogInitialLayout = true;
      // #region agent log
      _debugLog(
        hypothesisId: 'H1',
        location: 'student_location_screen.dart:build',
        message: 'Live screen scaffold metrics',
        data: {
          'topPadding': media.padding.top,
          'viewPaddingTop': media.viewPadding.top,
          'viewInsetsTop': media.viewInsets.top,
          'hasAppBar': true,
          'bodyType': 'Column(Expanded list + Expanded map)',
        },
      );
      // #endregion
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: assignedBuses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final buses = snapshot.data ?? [];
        if (!_didLogBusData && snapshot.connectionState == ConnectionState.done) {
          _didLogBusData = true;
          // #region agent log
          _debugLog(
            hypothesisId: 'H3',
            location: 'student_location_screen.dart:FutureBuilder',
            message: 'Live page data shape',
            data: {
              'hasError': snapshot.hasError,
              'busCount': buses.length,
              'usesListSectionAboveMap': true,
              'listFlex': 2,
              'mapFlex': 3,
            },
          );
          // #endregion
        }

        if (buses.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Bus Assignments"),
              backgroundColor: Colors.blue,
            ),
            body: const Center(child: Text("No assigned buses available")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Buses Live Location"),
            backgroundColor: Colors.blue,
          ),
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Bus Number: ${bus['busNumber']}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Route: ${bus['routeName']}'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 96,
                                maxWidth: 120,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _startDriverLocationTracking(bus['driverEmail']);
                                  _fetchRouteDetails(bus['routeName']);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("Live Location"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 3,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0.0, 0.0),
                    zoom: 5,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
