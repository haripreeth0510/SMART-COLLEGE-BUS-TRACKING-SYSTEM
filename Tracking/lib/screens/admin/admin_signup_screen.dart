import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  _AdminSignupScreenState createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Z])(?=.*\W)(?=.*[a-z]).{8,}$').hasMatch(password);
  }

  Future<void> handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('admins').doc(userCredential.user?.uid).set({
          'name': nameController.text,
          'email': emailController.text,
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Sign Up Successful', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: const Text('Your account has been created successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Admin Enrollment', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: AppTheme.pageBackgroundDecoration,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
          child: PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Administrator', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Text('Register to manage the fleet operations', style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Name',
                    controller: nameController,
                    prefixIcon: Icons.admin_panel_settings_rounded,
                    validator: (value) => (value == null || value.isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Email',
                    controller: emailController,
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || value.isEmpty || !value.endsWith('@srec.ac.in')) ? 'Must be @srec.ac.in' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Password',
                    controller: passwordController,
                    prefixIcon: Icons.lock_rounded,
                    obscureText: !_passwordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    validator: (value) => (value == null || value.isEmpty || !isValidPassword(value)) ? 'Weak password' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    prefixIcon: Icons.lock_clock_rounded,
                    obscureText: !_confirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                    validator: (value) => (value == null || value.isEmpty || value != passwordController.text) ? 'Mismatch' : null,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Create Admin Account',
                    onPressed: handleSignup,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
