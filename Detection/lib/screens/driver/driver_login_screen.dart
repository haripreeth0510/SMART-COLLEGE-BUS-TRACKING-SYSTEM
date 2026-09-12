import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  _DriverLoginScreenState createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _isLoading = false;

  Future<void> _loginDriver() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final driverEmail = userCredential.user?.email ?? '';

        QuerySnapshot assignmentSnapshot = await FirebaseFirestore.instance
            .collection('drivers')
            .where('email', isEqualTo: driverEmail)
            .limit(1)
            .get();

        if (assignmentSnapshot.docs.isNotEmpty) {
          final data = assignmentSnapshot.docs.first.data() as Map<String, dynamic>;
          final busNumber = data['busNumber'] ?? 'N/A';
          final routeName = data['routeName'] ?? 'N/A';

          Navigator.pushReplacementNamed(
            context,
            '/driver_dashboard',
            arguments: {
              'driverEmail': driverEmail,
              'busNumber': busNumber,
              'routeName': routeName,
            },
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No assignment found for this driver.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppTheme.primaryColor.withValues(alpha: 0.2),
              BlendMode.overlay,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.backgroundColor.withValues(alpha: 0.8),
                AppTheme.backgroundColor.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Driver Portal',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to start your route tracking',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.subtitleColor,
                          ),
                    ),
                    const SizedBox(height: 48),
                    PremiumCard(
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Driver Email',
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.drive_eta_outlined,
                            hintText: 'Enter your driver email',
                            validator: (value) => value == null || value.isEmpty ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: 'Password',
                            controller: passwordController,
                            obscureText: !_passwordVisible,
                            prefixIcon: Icons.lock_outline,
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                color: AppTheme.subtitleColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                          ),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                  label: 'Start Session',
                                  onPressed: _loginDriver,
                                  icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/driver_signup'),
                            child: const Text('New Driver? Create Account'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/driver_forgot_password'),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppTheme.subtitleColor),
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
