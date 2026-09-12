import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/custom_textfield.dart';
import '../../shared/custom_button.dart';
import '../../shared/premium_card.dart';
import '../../shared/theme.dart';

class StudentEditProfileScreen extends StatefulWidget {
  const StudentEditProfileScreen({super.key});

  @override
  _StudentEditProfileScreenState createState() => _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState extends State<StudentEditProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final routeController = TextEditingController();
  final pickupLocationController = TextEditingController();
  final addressController = TextEditingController();
  final departmentController = TextEditingController();
  final yearOfStudyController = TextEditingController();
  final dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _phoneError;
  DateTime? _selectedDob;
  bool _isLoading = true;

  bool isValidFullName(String name) => RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$').hasMatch(name);
  bool isValidPhoneNumber(String phone) => RegExp(r'^[0-9]{10}$').hasMatch(phone.replaceFirst('+91', ''));

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            nameController.text = data['name'] ?? '';
            phoneController.text = data['phone'] ?? '+91';
            routeController.text = data['assignedRoute'] ?? '';
            pickupLocationController.text = data['pickupLocation'] ?? '';
            addressController.text = data['address'] ?? '';
            departmentController.text = data['department'] ?? '';
            yearOfStudyController.text = data['yearOfStudy'] ?? '';
            dobController.text = data['dateOfBirth'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile details')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1980),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'assignedRoute': routeController.text.trim(),
          'pickupLocation': pickupLocationController.text.trim(),
          'address': addressController.text.trim(),
          'department': departmentController.text.trim(),
          'yearOfStudy': yearOfStudyController.text.trim(),
          'dateOfBirth': dobController.text.trim(),
        });
        
        if (!mounted) return;
        Navigator.pop(context); // remove loading and return success
        Navigator.pop(context, true); // return to home with a flag indicating updates
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // remove loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
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
                  Text('Update Details',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Text('Make sure all standard info fields are correct.',
                      style: GoogleFonts.outfit(color: AppTheme.subtitleColor)),
                  const SizedBox(height: 28),

                  // ── Personal Info ──────────────────────────────────
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Full Name',
                    controller: nameController,
                    prefixIcon: Icons.person_rounded,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[A-Za-z\s]*$'))],
                    validator: (value) =>
                        (value == null || value.isEmpty || !isValidFullName(value)) ? 'Enter a valid full name' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Phone Number',
                    controller: phoneController,
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) =>
                        setState(() => _phoneError = !isValidPhoneNumber(value) ? 'Invalid phone number' : null),
                    validator: (value) =>
                        (value == null || value.isEmpty || _phoneError != null) ? 'Enter a valid phone' : null,
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth — date picker
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        label: 'Date of Birth',
                        controller: dobController,
                        prefixIcon: Icons.cake_rounded,
                        hintText: 'DD/MM/YYYY',
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Select your date of birth' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Address',
                    controller: addressController,
                    prefixIcon: Icons.home_rounded,
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter your address' : null,
                  ),
                  const SizedBox(height: 28),

                  // ── Academic Info ──────────────────────────────────
                  _sectionLabel('Academic Information'),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Department',
                    controller: departmentController,
                    prefixIcon: Icons.school_rounded,
                    hintText: 'e.g. Computer Science',
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter your department' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Year of Study',
                    controller: yearOfStudyController,
                    prefixIcon: Icons.calendar_today_rounded,
                    hintText: 'e.g. 2nd Year',
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter your year of study' : null,
                  ),
                  const SizedBox(height: 28),

                  // ── Bus Details ──────────────────────────────────
                  _sectionLabel('Bus Details'),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'Assigned Route',
                    controller: routeController,
                    prefixIcon: Icons.route_rounded,
                    hintText: 'e.g. Route 3',
                    validator: (value) => (value == null || value.isEmpty) ? 'Route is required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Pickup Location / Stop Name',
                    controller: pickupLocationController,
                    prefixIcon: Icons.location_on_rounded,
                    hintText: 'e.g. Main Gate Stop',
                    validator: (value) => (value == null || value.isEmpty) ? 'Pickup location is required' : null,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Save Profile Changes',
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
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
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }
}
