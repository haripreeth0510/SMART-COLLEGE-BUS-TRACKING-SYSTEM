import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/gps_tracking_service.dart';
import '../../shared/theme.dart';
import '../../shared/premium_card.dart';
import 'driver_profile_screen.dart';
import 'driver_view_feedback_screen.dart';
import 'driver_route_overview_screen.dart';
import '../shared/bus_logs_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> driverAssignment;
  String? driverEmail = FirebaseAuth.instance.currentUser?.email;

  Future<Map<String, dynamic>> fetchDriverAssignment(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('assignments')
          .where('driverEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    if (driverEmail != null) {
      driverAssignment = fetchDriverAssignment(driverEmail!);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (driverEmail == null) {
      return const Scaffold(body: Center(child: Text("Error: Driver email not found")));
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: driverAssignment,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        final data = snapshot.data ?? {};

        final List<Widget> widgetOptions = [
          DriverHomePageContent(
            busNumber: data['busNumber'] ?? 'Not Assigned',
            routeName: data['routeName'] ?? 'Not Assigned',
          ),
          DriverRouteOverviewScreen(
            driverEmail: driverEmail!,
            busNumber: data['busNumber'] ?? '',
            routeName: data['routeName'] ?? '',
            busId: data['busId'] ?? '',
            routeId: data['routeId'] ?? '',
          ),
          const DriverProfileScreen(),
          const DriverViewFeedbackScreen(),
          const BusLogsScreen(),
        ];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text('Driver Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _logout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: widgetOptions,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              elevation: 0,
              backgroundColor: Colors.white,
              indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus_rounded), label: 'Route'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
                NavigationDestination(icon: Icon(Icons.feedback_outlined), selectedIcon: Icon(Icons.feedback_rounded), label: 'Feedback'),
                NavigationDestination(icon: Icon(Icons.history_edu_outlined), selectedIcon: Icon(Icons.history_edu_rounded), label: 'Logs'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DriverHomePageContent extends StatefulWidget {
  final String busNumber;
  final String routeName;

  const DriverHomePageContent({required this.busNumber, required this.routeName, super.key});

  @override
  State<DriverHomePageContent> createState() => _DriverHomePageContentState();
}

class _DriverHomePageContentState extends State<DriverHomePageContent> {
  bool _isTracking = false;
  Position? _currentLocation;
  GoogleMapController? _mapController;
  final GpsTrackingService _gpsService = GpsTrackingService();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<LatLng> routeCoordinates = [];
  List<LatLng> traveledCoordinates = [];

  Future<void> _getRoutePolyline() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('route', isEqualTo: widget.routeName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final routeData = snapshot.docs.first.data();
        List<LatLng> coordinates = [];
        routeData['trips'].forEach((trip, stops) {
          stops.forEach((stop) {
            final rawCoords = stop['coordinates'] as String;
            final cleanCoords = rawCoords.replaceAll(RegExp(r'[^\d.,-]'), '');
            final coords = cleanCoords.split(',');
            
            if (coords.length >= 2) {
              final lat = double.tryParse(coords[0]);
              final lng = double.tryParse(coords[1]);
              
              if (lat != null && lng != null) {
                final latLng = LatLng(lat, lng);
                coordinates.add(latLng);

                _markers.add(Marker(
                  markerId: MarkerId(stop['stop'] ?? 'Unknown Stop'),
                  position: latLng,
                  icon: BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(title: stop['stop']),
                ));
              }
            }
          });
        });

        setState(() {
          routeCoordinates = coordinates;
          _polylines.add(Polyline(
            polylineId: const PolylineId('remainingPolyline'),
            points: routeCoordinates,
            color: AppTheme.primaryColor,
            width: 5,
          ));
        });
      }
    } catch (e) {
      print("Error fetching route polyline: $e");
    }
  }

  Future<void> _startTracking() async {
    final hasPermission = await GpsTrackingService.requestPermission();
    if (!mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied!')));
      return;
    }

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    setState(() => _isTracking = true);

    _gpsService.startTracking(
      driverEmail: email,
      routeId: widget.routeName,
      onPositionUpdate: (Position position) {
        final LatLng currentLatLng = LatLng(position.latitude, position.longitude);
        traveledCoordinates.add(currentLatLng);
        List<LatLng> remainingCoordinates = routeCoordinates.where((point) => !traveledCoordinates.contains(point)).toList();

        if (!mounted) return;
        setState(() {
          _currentLocation = position;
          _markers.removeWhere((marker) => marker.markerId.value == 'driverLocation');
          _markers.add(Marker(
            markerId: const MarkerId('driverLocation'),
            position: currentLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: "Your Location"),
          ));

          _polylines.clear();
          _polylines.add(Polyline(polylineId: const PolylineId('traveled'), points: traveledCoordinates, color: Colors.green, width: 6));
          _polylines.add(Polyline(polylineId: const PolylineId('remaining'), points: remainingCoordinates, color: AppTheme.primaryColor, width: 4, patterns: [PatternItem.dash(10), PatternItem.gap(10)]));
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
      },
    );
  }

  Future<void> _stopTracking() async {
    _gpsService.stopTracking();
    setState(() => _isTracking = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip stopped.')));
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getRoutePolyline();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.backgroundColor,
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: PremiumCard(
            gradient: AppTheme.primaryGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Mission', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(widget.routeName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.busNumber, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTracking ? null : _startTracking,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTracking ? _stopTracking : null,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation != null ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude) : const LatLng(10.8505, 76.2711),
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                polylines: _polylines,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                style: '''[]''', // Optional: Add a custom map style here
              ),
            ),
          ),
        ),
      ],
    );
  }
}
