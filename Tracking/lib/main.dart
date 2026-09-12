import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:campus_go/firebase_options.dart';

// Shared / Unified Auth
import 'screens/shared/unified_login_screen.dart';
import 'screens/shared/unified_signup_screen.dart';
import 'screens/shared/unified_forgot_password_screen.dart';
import 'screens/shared/bus_logs_screen.dart';

// Student Screens
import 'screens/student/student_home_screen.dart';
import 'screens/student/student_location_screen.dart';
import 'screens/student/student_search_screen.dart';
import 'screens/student/student_notifications_screen.dart';
import 'screens/student/student_routes_screen.dart';
import 'screens/student/student_edit_profile_screen.dart';

// Driver Screens
import 'screens/driver/driver_dashboard_screen.dart';
import 'screens/driver/driver_route_overview_screen.dart';
import 'screens/driver/driver_profile_screen.dart';
import 'screens/driver/driver_view_feedback_screen.dart';

// Admin Screens
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_manage_buses_screen.dart' as buses_screen;
import 'screens/admin/admin_manage_drivers_screen.dart' as drivers_screen;
import 'screens/admin/admin_driver_edit_screen.dart';
import 'screens/admin/admin_register_driver_screen.dart';
import 'screens/admin/admin_route_management_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';
import 'screens/admin/admin_view_feedback_screen.dart';
import 'screens/admin/assign_bus_route_screen.dart';

import 'shared/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SRECBusManagementApp());
}

class SRECBusManagementApp extends StatelessWidget {
  const SRECBusManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SREC Bus Management',
      theme: AppTheme.themeData,
      debugShowCheckedModeBanner: false,
      // ─── Single entry point for ALL roles ───
      initialRoute: '/login',
      routes: {
        // ── Unified Auth ──
        '/login': (context) => const UnifiedLoginScreen(),
        '/signup': (context) => const UnifiedSignupScreen(),
        '/forgot_password': (context) => const UnifiedForgotPasswordScreen(),

        // ── Student ──
        '/student_home': (context) => const StudentHomeScreen(),
        '/student_location': (context) => const StudentLocationScreen(),
        '/student_search': (context) => const StudentSearchScreen(),
        '/student_notifications': (context) => const StudentNotificationsScreen(),
        '/student_routes': (context) => const StudentRoutesScreen(),
        '/student_edit_profile': (context) => const StudentEditProfileScreen(),

        // ── Driver ──
        '/driver_dashboard': (context) => const DriverDashboardScreen(),
        '/driver_profile': (context) => const DriverProfileScreen(),
        '/driver_view_feedback': (context) => const DriverViewFeedbackScreen(),

        // ── Admin ──
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/admin_manage_buses': (context) => const buses_screen.AdminManageBusesScreen(),
        '/admin_manage_drivers': (context) => const drivers_screen.AdminManageDriversScreen(),
        '/admin_register_driver': (context) => const AdminRegisterDriverScreen(),
        '/admin_route_management': (context) => const AdminRouteManagementScreen(),
        '/admin_analytics': (context) => const AdminAnalyticsScreen(),
        '/admin_view_feedback': (context) => const AdminViewFeedbackScreen(),
        '/assign_bus_route': (context) => const AssignBusRouteScreen(),
        '/admin_bus_logs': (context) => const BusLogsScreen(),

        // ── Shared ──
        '/bus_logs': (context) => const BusLogsScreen(),
      },

      // Driver route overview needs arguments — handled via onGenerateRoute
      onGenerateRoute: (settings) {
        if (settings.name == '/driver_route_overview') {
          if (settings.arguments is Map<String, String>) {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => DriverRouteOverviewScreen(
                driverEmail: args['driverEmail'] ?? '',
                busNumber: args['busNumber'] ?? '',
                routeName: args['routeName'] ?? '',
                busId: args['busId'] ?? '',
                routeId: args['routeId'] ?? '',
              ),
            );
          }
        }
        if (settings.name == '/admin_driver_edit') {
          if (settings.arguments is Map<String, String>) {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => AdminDriverEditScreen(
                driverId: args['driverId'] ?? '',
                name: args['name'] ?? '',
                email: args['email'] ?? '',
                phone: args['phone'] ?? '',
                licenseNumber: args['licenseNumber'] ?? '',
              ),
            );
          }
        }
        // Fallback: redirect unknown routes to login
        return MaterialPageRoute(builder: (context) => const UnifiedLoginScreen());
      },
    );
  }
}
