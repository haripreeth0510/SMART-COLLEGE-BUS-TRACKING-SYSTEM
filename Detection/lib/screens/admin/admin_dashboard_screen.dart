import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildAnimatedActionCard(
    BuildContext context, {
    required _DashboardAction action,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 110)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: action.iconBgColor,
            child: Icon(action.icon, color: action.iconColor),
          ),
          title: Text(
            action.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(action.subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onTap: () => Navigator.pushNamed(context, action.route),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const actions = <_DashboardAction>[
      _DashboardAction(
        title: 'Manage Buses',
        subtitle: 'Add, edit and monitor bus details',
        icon: Icons.directions_bus_rounded,
        route: '/admin_manage_buses',
        iconBgColor: Color(0xFFFFE2EB),
        iconColor: Color(0xFFEF476F),
      ),
      _DashboardAction(
        title: 'Manage Drivers',
        subtitle: 'Handle driver profiles and records',
        icon: Icons.person_rounded,
        route: '/admin_manage_drivers',
        iconBgColor: Color(0xFFE5FAF5),
        iconColor: Color(0xFF06D6A0),
      ),
      _DashboardAction(
        title: 'Route Management',
        subtitle: 'Create and maintain route trips',
        icon: Icons.route_rounded,
        route: '/admin_route_management',
        iconBgColor: Color(0xFFFFF1DF),
        iconColor: Color(0xFFFF9F1C),
      ),
      _DashboardAction(
        title: 'Analytics',
        subtitle: 'Review performance insights',
        icon: Icons.analytics_rounded,
        route: '/admin_analytics',
        iconBgColor: Color(0xFFE8ECFF),
        iconColor: Color(0xFF5E60CE),
      ),
      _DashboardAction(
        title: 'Bus & Route Assignment',
        subtitle: 'Assign buses and routes to drivers',
        icon: Icons.assignment_rounded,
        route: '/assign_bus_route',
        iconBgColor: Color(0xFFE7F0FF),
        iconColor: Color(0xFF3A86FF),
      ),
      _DashboardAction(
        title: 'Campus Bus Logs',
        subtitle: 'View live bus detections',
        icon: Icons.history_edu_rounded,
        route: '/admin_bus_logs',
        iconBgColor: Color(0xFFFBE4D2),
        iconColor: Color(0xFFE07A5F),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageBackgroundDecoration,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operations Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Manage buses, drivers and routes from one smooth dashboard.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < actions.length; i++)
              _buildAnimatedActionCard(
                context,
                action: actions[i],
                index: i,
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color iconBgColor;
  final Color iconColor;

  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.iconBgColor,
    required this.iconColor,
  });
}
