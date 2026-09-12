/// Represents a user (student, driver, or admin) in the system.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student', 'driver', 'admin'
  final String? phone;
  final String? assignedRoute;
  final String? licenseNumber; // driver-specific

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.assignedRoute,
    this.licenseNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      uid: docId ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      phone: map['phone'],
      assignedRoute: map['assignedRoute'],
      licenseNumber: map['licenseNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'assignedRoute': assignedRoute,
      'licenseNumber': licenseNumber,
    };
  }
}
