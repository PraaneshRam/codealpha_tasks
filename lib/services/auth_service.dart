import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Check if username is available
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (usernameDoc.exists) {
        throw 'Username is already taken';
      }

      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Reserve username
      await _firestore.collection('usernames').doc(username.toLowerCase()).set({
        'uid': credential.user!.uid,
        'username': username,
      });

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateProfile({String? username, String? email}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      final updates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (username != null) {
        // Check if new username is available
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .get();

        if (usernameDoc.exists) {
          throw 'Username is already taken';
        }

        // Get current username
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final currentUsername = userDoc.data()?['username'] as String?;

        if (currentUsername != null) {
          // Delete old username document
          await _firestore
              .collection('usernames')
              .doc(currentUsername.toLowerCase())
              .delete();
        }

        // Create new username document
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .set({
          'uid': user.uid,
          'username': username,
        });

        updates['username'] = username;
      }

      if (email != null && email != user.email) {
        await user.updateEmail(email);
        updates['email'] = email;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Reauthenticate user before deleting account
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] as String?;

      // Delete username reservation
      if (username != null) {
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete();
      }

      // Delete user document and all subcollections
      await _deleteUserData(user.uid);

      // Delete user account
      await user.delete();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Helper method to delete user data and subcollections
  Future<void> _deleteUserData(String uid) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(uid);

    // Delete main user document
    batch.delete(userRef);

    // Delete subcollections
    final subcollections = [
      'activities',
      'nutrition_history',
      'water_intake',
      'workoutProgress',
      'body_analysis',
      'photos',
    ];

    for (final collection in subcollections) {
      final querySnapshot = await userRef.collection(collection).get();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  // Helper method to handle auth exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'email-already-in-use':
          return 'Email is already in use';
        case 'weak-password':
          return 'Password is too weak';
        case 'invalid-email':
          return 'Invalid email address';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'user-disabled':
          return 'User has been disabled';
        case 'requires-recent-login':
          return 'Please log in again to complete this action';
        default:
          return 'Authentication error: ${e.message}';
      }
    }
    return e.toString();
  }
}
