import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  _DriverSignupScreenState createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController(text: '+91');
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final licenseNumberController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Email validation
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Password validation
  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Z])(?=.*\W)(?=.*[a-z]).{8,}$').hasMatch(password);
  }

  // Confirm password validation
  bool doPasswordsMatch() {
    return passwordController.text == confirmPasswordController.text;
  }

  // Function to sign up a new driver
  Future<void> _signUpDriver() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Create new user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim());

        // Save driver details to Firestore
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(userCredential.user?.uid)
            .set({
          'name': nameController.text,
          'phone': phoneController.text,
          'email': emailController.text,
          'licenseNumber': licenseNumberController.text,
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Signup Successful', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: const Text('Your driver account has been created.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Driver Registration', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
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
                  Text('Captain Account', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Text('Join the professional fleet team', style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
                  const SizedBox(height: 32),
                  // Name Input Field
                  CustomTextField(
                    label: 'Full Name',
                    controller: nameController,
                    prefixIcon: Icons.badge_rounded,
                    helperText: 'Enter full name as per DL',
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Phone Number Input Field
                  CustomTextField(
                    label: 'Phone Number',
                    controller: phoneController,
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Email Input Field
                  CustomTextField(
                    label: 'Email',
                    controller: emailController,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      } else if (!isValidEmail(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // License Number Input Field
                  CustomTextField(
                    label: 'License Number',
                    controller: licenseNumberController,
                    prefixIcon: Icons.credit_card_rounded,
                    helperText: 'Format: TN23 20220004001',
                    validator: (value) =>
                        value == null || value.isEmpty ? 'License is required' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password Input Field
                  CustomTextField(
                    label: 'Password',
                    controller: passwordController,
                    prefixIcon: Icons.key_rounded,
                    obscureText: !_passwordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      } else if (!isValidPassword(value)) {
                        return 'Password must include uppercase, special char, and 8+ chars';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password Input Field
                  CustomTextField(
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    prefixIcon: Icons.check_circle_outline_rounded,
                    obscureText: !_confirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (!doPasswordsMatch()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Sign Up Button
                  CustomButton(
                    label: 'Register Account',
                    onPressed: _signUpDriver,
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
