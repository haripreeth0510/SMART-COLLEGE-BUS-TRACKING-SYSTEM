import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/theme.dart';

class UnifiedForgotPasswordScreen extends StatefulWidget {
  const UnifiedForgotPasswordScreen({super.key});

  @override
  State<UnifiedForgotPasswordScreen> createState() => _UnifiedForgotPasswordScreenState();
}

class _UnifiedForgotPasswordScreenState extends State<UnifiedForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResetSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _isResetSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send reset email.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset Password',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the email address associated with your account. A reset link will be sent to your inbox.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isResetSent) ...[
                  CustomTextField(
                    label: 'Email Address',
                    controller: emailController,
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'Enter your registered email',
                  ),
                  const SizedBox(height: 28),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : CustomButton(
                          label: 'Send Reset Link',
                          onPressed: _sendResetLink,
                          icon: const Icon(Icons.send_rounded, size: 20),
                        ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Email Sent!',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A password reset link has been sent to ${emailController.text}. Please check your inbox.',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    label: 'Back to Login',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
