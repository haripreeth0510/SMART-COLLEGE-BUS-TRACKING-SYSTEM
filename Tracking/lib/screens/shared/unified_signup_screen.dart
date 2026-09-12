import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

enum UserRole { student, driver, admin }

class UnifiedSignupScreen extends StatefulWidget {
  const UnifiedSignupScreen({super.key});

  @override
  State<UnifiedSignupScreen> createState() => _UnifiedSignupScreenState();
}

class _UnifiedSignupScreenState extends State<UnifiedSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Shared Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Student/Driver specific
  final phoneController = TextEditingController(text: '+91');
  // Student-specific
  final routeController = TextEditingController();
  // Driver-specific
  final licenseController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    routeController.dispose();
    licenseController.dispose();
    super.dispose();
  }

  bool isValidPassword(String password) =>
      RegExp(r'^(?=.*[A-Z])(?=.*\W)(?=.*[a-z]).{8,}$').hasMatch(password);

  bool isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  String get _collectionName {
    switch (_selectedRole) {
      case UserRole.student: return 'students';
      case UserRole.driver: return 'drivers';
      case UserRole.admin: return 'admins';
    }
  }

  Map<String, dynamic> _buildUserData() {
    final base = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'createdAt': Timestamp.now(),
    };
    switch (_selectedRole) {
      case UserRole.student:
        return {...base, 'phone': phoneController.text.trim(), 'assignedRoute': routeController.text.trim()};
      case UserRole.driver:
        return {...base, 'phone': phoneController.text.trim(), 'licenseNumber': licenseController.text.trim()};
      case UserRole.admin:
        return base;
    }
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = credential.user?.uid;
      if (uid == null) throw Exception('User creation failed.');

      await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(uid)
          .set(_buildUserData());

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Account Created!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text(
            'Your ${_selectedRole.name} account has been created successfully. Please log in.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.message}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleSelectorCard() {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = _selectedRole == role;
        final (icon, label, color) = switch (role) {
          UserRole.student => (Icons.school_rounded, 'Student', AppTheme.secondaryColor),
          UserRole.driver => (Icons.drive_eta_rounded, 'Driver', AppTheme.accentColor),
          UserRole.admin => (Icons.admin_panel_settings_rounded, 'Admin', const Color(0xFF06D6A0)),
        };
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : AppTheme.primaryColor.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isSelected ? color : AppTheme.subtitleColor, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Create Account', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 110, 24, 40),
            child: PremiumCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register as',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your role to get started',
                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.subtitleColor),
                    ),
                    const SizedBox(height: 20),

                    // Role Selector
                    _buildRoleSelectorCard(),
                    const SizedBox(height: 28),

                    // --- Shared Fields ---
                    CustomTextField(
                      label: 'Full Name',
                      controller: nameController,
                      prefixIcon: Icons.person_rounded,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[A-Za-z\s]*$'))],
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone number — show for student and driver only
                    if (_selectedRole != UserRole.admin) ...[
                      CustomTextField(
                        label: 'Phone Number',
                        controller: phoneController,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone is required';
                          final digits = v.replaceFirst('+91', '');
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(digits)) return 'Enter valid 10-digit number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Student-specific: Assigned Route
                    if (_selectedRole == UserRole.student) ...[
                      CustomTextField(
                        label: 'Assigned Route',
                        controller: routeController,
                        prefixIcon: Icons.route_rounded,
                        hintText: 'e.g. Route A, Bangalore - Kolar',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Route is required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Driver-specific: License Number
                    if (_selectedRole == UserRole.driver) ...[
                      CustomTextField(
                        label: 'License Number',
                        controller: licenseController,
                        prefixIcon: Icons.credit_card_rounded,
                        hintText: 'e.g. TN23 20220004001',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'License number is required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email
                    CustomTextField(
                      label: 'College Email',
                      controller: emailController,
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!isValidEmail(v)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    CustomTextField(
                      label: 'Password',
                      controller: passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: !_passwordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (!isValidPassword(v)) return 'Min 8 chars, 1 uppercase, 1 special character';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    CustomTextField(
                      label: 'Confirm Password',
                      controller: confirmPasswordController,
                      prefixIcon: Icons.lock_clock_rounded,
                      obscureText: !_confirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            label: 'Create Account',
                            onPressed: _handleSignup,
                          ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.outfit(color: AppTheme.subtitleColor, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
