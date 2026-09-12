import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  bool _passwordVisible = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Authentication failed.');

      final role = await _firebaseService.getUserRole(uid);
      if (!mounted) return;

      switch (role) {
        case 'student':
          Navigator.pushNamedAndRemoveUntil(context, '/student_home', (_) => false);
          break;
        case 'driver':
          Navigator.pushNamedAndRemoveUntil(context, '/driver_dashboard', (_) => false);
          break;
        case 'admin':
          Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (_) => false);
          break;
        default:
          // User exists in Firebase Auth but not in any Firestore collection
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account not found. Please register first.'),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // App logo/icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'SREC Bus Management',
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Smart College Bus Tracking System',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Role badges for visual context
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoleBadge(icon: Icons.school_rounded, label: 'Student', color: AppTheme.secondaryColor),
                        const SizedBox(width: 10),
                        _RoleBadge(icon: Icons.drive_eta_rounded, label: 'Driver', color: AppTheme.accentColor),
                        const SizedBox(width: 10),
                        _RoleBadge(icon: Icons.admin_panel_settings_rounded, label: 'Admin', color: const Color(0xFF06D6A0)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    PremiumCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue — we\'ll detect your role automatically.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 28),
                            CustomTextField(
                              label: 'Email Address',
                              controller: emailController,
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Enter your registered email',
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email is required';
                                if (!value.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: 'Password',
                              controller: passwordController,
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: !_passwordVisible,
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.subtitleColor,
                                ),
                                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : CustomButton(
                                    label: 'Sign In',
                                    onPressed: _handleLogin,
                                    icon: const Icon(Icons.login_rounded, size: 20),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signup'),
                            child: Text(
                              'Register Now',
                              style: GoogleFonts.outfit(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RoleBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
