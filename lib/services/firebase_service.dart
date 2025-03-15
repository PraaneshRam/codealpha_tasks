import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Starting login process for email: $email'); // Debug log

      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Connection timed out. Please check your internet.',
          );
        },
      );

      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'auth-error',
          message: 'Failed to get user data after sign in',
        );
      }

      // Update last login time
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error during login: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Starting registration process for email: $email'); // Debug log

      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Email and password cannot be empty',
        );
      }

      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'registration-error',
          message: 'Failed to create user account',
        );
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'photos': [],
        'progress': {
          'steps': 0,
          'waterIntake': 0,
          'workouts': [],
        },
        'settings': {
          'notifications': true,
          'darkMode': true,
          'units': 'metric',
        },
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException during registration: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      throw FirebaseAuthException(
        code: 'sign-out-error',
        message: 'Failed to sign out. Please try again.',
      );
    }
  }

  // Get user data
  Future<DocumentSnapshot> getUserData() async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }
    return await _firestore.collection('users').doc(currentUserId).get();
  }

  // Update user data
  Future<void> updateUserData({
    required String email,
    String? username,
    Map<String, dynamic>? settings,
  }) async {
    if (currentUserId == null) return;

    final data = {
      'email': email,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (username != null) data['username'] = username;
    if (settings != null) data['settings'] = settings;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .set(data, SetOptions(merge: true));
  }

  // Update workout progress
  Future<void> updateWorkoutProgress({
    required String date,
    required int steps,
    required int waterIntake,
    required List<Map<String, dynamic>> workoutProgress,
  }) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workoutProgress')
        .doc(date)
        .set({
      'steps': steps,
      'water_intake': waterIntake,
      'workoutProgress': workoutProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get workout progress for a specific date
  Future<DocumentSnapshot> getWorkoutProgress(String date) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }
    return await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workoutProgress')
        .doc(date)
        .get();
  }

  // Initialize today's workout progress if not exists
  Future<void> initializeTodayProgress() async {
    if (currentUserId == null) return;

    final date = getTodayDate();
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workoutProgress')
        .doc(date)
        .get();

    if (!doc.exists) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('workoutProgress')
          .doc(date)
          .set({
        'steps': 0,
        'water_intake': 0,
        'workoutProgress': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get today's date in the format YYYY-MM-DD
  String getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
