import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  User? get currentUser => _auth.currentUser;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Firestore: Student Data
  Future<Map<String, dynamic>?> getStudentData(String uid) async {
    final doc = await _firestore.collection('students').doc(uid).get();
    return doc.data();
  }

  // Firestore: Bus Assignments
  Future<List<Map<String, dynamic>>> getAssignedBuses(String routeName) async {
    final snapshot = await _firestore
        .collection('assignments')
        .where('routeName', isEqualTo: routeName)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Firestore: Bus Detections (Live Status)
  Stream<QuerySnapshot> getLatestBusDetection(String busPlate) {
    return _firestore
        .collection('buses_detected')
        .where('plate_number', isEqualTo: busPlate)
        .orderBy('detected_at', descending: true)
        .limit(1)
        .snapshots();
  }

  // Firestore: All Bus Logs
  Stream<QuerySnapshot> getBusLogs() {
    return _firestore
        .collection('buses_detected')
        .orderBy('detected_at', descending: true)
        .snapshots();
  }

  // Role Resolution: Determine role by checking all user collections
  Future<String?> getUserRole(String uid) async {
    final collections = ['students', 'drivers', 'admins'];
    for (final collection in collections) {
      final doc = await _firestore.collection(collection).doc(uid).get();
      if (doc.exists) {
        // Return singular role name
        return collection.endsWith('s') ? collection.substring(0, collection.length - 1) : collection;
      }
    }
    return null; // Unknown or unregistered user
  }
}
