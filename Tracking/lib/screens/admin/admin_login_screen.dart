import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _passwordVisible = false;

  Future<void> handleLogin() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
            image: const NetworkImage('https://images.unsplash.com/photo-1454165833767-027fffdce639?q=80&w=2070&auto=format&fit=crop'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppTheme.primaryColor.withValues(alpha: 0.15),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Admin Access',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage the campus fleet and routes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.subtitleColor,
                        ),
                  ),
                  const SizedBox(height: 48),
                  PremiumCard(
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Admin Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.admin_panel_settings_outlined,
                          hintText: 'Enter admin email',
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          controller: passwordController,
                          obscureText: !_passwordVisible,
                          prefixIcon: Icons.lock_outline,
                          hintText: 'Enter secure password',
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
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          label: 'Login as Admin',
                          onPressed: handleLogin,
                          icon: const Icon(Icons.security_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin_signup'),
                          child: const Text('New Admin? Register Here'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin_forgot_password'),
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
    );
  }
}
