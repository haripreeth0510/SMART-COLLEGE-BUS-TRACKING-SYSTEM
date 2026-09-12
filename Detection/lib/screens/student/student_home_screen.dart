import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';
import 'student_location_screen.dart';
import 'student_notifications_screen.dart';
import 'student_routes_screen.dart';
import 'student_search_screen.dart';
import '../shared/bus_logs_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  int? _lastLoggedIndex;

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

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePageContent(),
    const StudentSearchScreen(),
    const StudentLocationScreen(),
    const StudentRoutesScreen(),
    const StudentNotificationsScreen(),
    const BusLogsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastLoggedIndex != _selectedIndex) {
      _lastLoggedIndex = _selectedIndex;
      final media = MediaQuery.of(context);
      // #region agent log
      _debugLog(
        hypothesisId: 'H2',
        location: 'student_home_screen.dart:build',
        message: 'Student home tab selected',
        data: {
          'selectedIndex': _selectedIndex,
          'selectedWidget': _widgetOptions[_selectedIndex].runtimeType.toString(),
          'outerScaffoldExtendBodyBehindAppBar': true,
          'outerHasAppBar': true,
          'topPadding': media.padding.top,
        },
      );
      // #endregion
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SREC Bus Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.accentColor),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                _logout();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOutBack,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _widgetOptions[_selectedIndex],
        ),
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
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Live'),
            NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus), label: 'Routes'),
            NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.history_edu_outlined), selectedIcon: Icon(Icons.history_edu), label: 'Logs'),
          ],
        ),
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final TextEditingController _feedbackController = TextEditingController();
  // Bus
  String? _assignedRoute;
  String? _assignedBusPlate;
  // Profile
  String? _studentName;
  String? _studentPhone;
  String? _studentEmail;
  String? _pickupLocation;
  String? _address;
  String? _department;
  String? _yearOfStudy;
  String? _dateOfBirth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentAndBusInfo();
  }

  Future<void> _fetchStudentAndBusInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (!studentDoc.exists || !mounted) return;

        final data = studentDoc.data() ?? {};
        final route = data['assignedRoute'] as String?;

        String? busPlate;
        if (route != null && route.isNotEmpty) {
          final assignmentSnapshot = await FirebaseFirestore.instance
              .collection('assignments')
              .where('routeName', isEqualTo: route)
              .get();
          if (assignmentSnapshot.docs.isNotEmpty) {
            busPlate = assignmentSnapshot.docs.first.data()['numberPlate'];
          }
        }

        if (mounted) {
          setState(() {
            _assignedRoute = route;
            _assignedBusPlate = busPlate;
            _studentName = data['name'];
            _studentPhone = data['phone'];
            _studentEmail = data['email'] ?? user.email;
            _pickupLocation = data['pickupLocation'];
            _address = data['address'];
            _department = data['department'];
            _yearOfStudy = data['yearOfStudy'];
            _dateOfBirth = data['dateOfBirth'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching student/bus info: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback cannot be empty.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit feedback.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'feedback': feedback,
        'userId': user.uid,
        'email': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _feedbackController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your feedback was submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving feedback: ${e.toString()}')),
      );
    }
  }

  Widget _buildProfileCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (_studentName?.isNotEmpty == true)
                        ? _studentName![0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName ?? 'Student',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _studentEmail ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _yearOfStudy ?? 'Student',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.primaryColor.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 20),
          // Details grid
          _profileRow(Icons.phone_rounded, 'Mobile', _studentPhone),
          _profileRow(Icons.cake_rounded, 'Date of Birth', _dateOfBirth),
          _profileRow(Icons.school_rounded, 'Department', _department),
          _profileRow(Icons.home_rounded, 'Address', _address),
          _profileRow(Icons.route_rounded, 'Assigned Route', _assignedRoute),
          _profileRow(
            Icons.location_on_rounded,
            'Pickup Location',
            _pickupLocation,
            isLast: true,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _profileRow(
    IconData icon,
    String label,
    String? value, {
    bool isLast = false,
    bool highlight = false,
  }) {
    final color = highlight ? AppTheme.accentColor : AppTheme.primaryColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.isNotEmpty == true ? value! : '—',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: highlight ? AppTheme.accentColor : AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStatusCard() {
    if (_isLoading) {
      return const PremiumCard(child: Center(child: CircularProgressIndicator()));
    }

    if (_assignedRoute == null) {
      return PremiumCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Route Assigned', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('Contact admin to assign a route', style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buses_detected')
          .where('plate_number', isEqualTo: _assignedBusPlate)
          .orderBy('detected_at', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        bool detectedAtGate = false;
        String timeAgo = '';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final doc = snapshot.data!.docs.first;
          final timestamp = (doc['detected_at'] as Timestamp).toDate();
          final difference = DateTime.now().difference(timestamp);
          if (difference.inHours < 1) {
            detectedAtGate = true;
            timeAgo = '${difference.inMinutes} mins ago';
          }
        }

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bus Status: $_assignedRoute',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  if (detectedAtGate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'AT GATE',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (detectedAtGate ? Colors.green : AppTheme.primaryColor).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: detectedAtGate ? Colors.green : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detectedAtGate ? 'Detected at college gate' : 'On route / Not detected',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          detectedAtGate ? 'Arrival: $timeAgo' : 'Waiting for real-time update...',
                          style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pushNamed(context, '/student_location'),
                    icon: const Icon(Icons.my_location_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${_studentName?.split(' ').first ?? 'Student'}! 👋',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      'Ready for your commute?',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.subtitleColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Bus Status Card ───────────────────────────────────
            _buildTrackingStatusCard(),
            const SizedBox(height: 24),
            // ── My Profile Card ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'My Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () async {
                    final didUpdate = await Navigator.pushNamed(context, '/student_edit_profile');
                    if (didUpdate == true) {
                      setState(() {
                         _isLoading = true;
                      });
                      _fetchStudentAndBusInfo();
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _isLoading
                ? const PremiumCard(child: Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())))
                : _buildProfileCard(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _QuickActionTile(
                  icon: Icons.search_rounded,
                  label: 'Find Routes',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.pushNamed(context, '/student_search'),
                ),
                _QuickActionTile(
                  icon: Icons.map_rounded,
                  label: 'Live Track',
                  color: AppTheme.secondaryColor,
                  onTap: () => Navigator.pushNamed(context, '/student_location'),
                ),
                _QuickActionTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  color: AppTheme.accentColor,
                  onTap: () => Navigator.pushNamed(context, '/student_notifications'),
                ),
                _QuickActionTile(
                  icon: Icons.history_edu_rounded,
                  label: 'Bus Logs',
                  color: Colors.indigo,
                  onTap: () => Navigator.pushNamed(context, '/bus_logs'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            PremiumCard(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We value your feedback',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve our service by sharing your experience.',
                    style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: '',
                    controller: _feedbackController,
                    hintText: 'Share your thoughts...',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Send Feedback'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryColor),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFDCE4F3)),
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }
}
