import 'package:fitness7/screens/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  Future<bool> _isUsernameAvailable(String username) async {
    if (username.toLowerCase() == _usernameController.text.toLowerCase()) {
      return true;
    }
    final usernameDoc =
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username.toLowerCase())
            .get();
    return !usernameDoc.exists;
  }

  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Check if new username is available
      if (!await _isUsernameAvailable(newUsername)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken')),
          );
        }
        return;
      }

      // Get current username
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final currentUsername = userDoc.data()?['username'] as String?;

      if (currentUsername != null) {
        // Delete old username document
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(currentUsername.toLowerCase())
            .delete();
      }

      // Create new username document
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(newUsername.toLowerCase())
          .set({'uid': user.uid, 'updatedAt': FieldValue.serverTimestamp()});

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'username': newUsername,
            'usernameLower': newUsername.toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating username: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to logout')));
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get current username
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final username = userDoc.data()?['username'] as String?;

      if (username != null) {
        // Delete username document
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username.toLowerCase())
            .delete();
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete the user account
      await user.delete();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account')),
        );
      }
    }
  }

  Future<void> _handlePasswordChange() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with this account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Password Reset Email Sent',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'A password reset link has been sent to ${user.email}. Please check your email to reset your password.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final username = userData?['username'] ?? 'User';

          if (!_isEditing) {
            _usernameController.text = username;
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue,
                              child: Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isEditing) ...[
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        onPressed:
                                            _isLoading ? null : _updateUsername,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : () => setState(
                                                  () => _isEditing = false,
                                                ),
                                      ),
                                    ],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (value.length < 3) {
                                    return 'Username must be at least 3 characters';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9_]+$',
                                  ).hasMatch(value)) {
                                    return 'Username can only contain letters, numbers, and underscores';
                                  }
                                  return null;
                                },
                                style: const TextStyle(color: Colors.white),
                              ),
                            ] else ...[
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => setState(() => _isEditing = true),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edit username',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildProfileSection('Account Settings', [
                        _buildProfileTile(
                          'Change Password',
                          Icons.lock_outline,
                          _handlePasswordChange,
                        ),
                        _buildProfileTile(
                          'Notifications',
                          Icons.notifications_outlined,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildProfileSection('App Settings', [
                        _buildProfileTile('Language', Icons.language, () {
                          // TODO: Implement language settings
                        }),
                        _buildProfileTile(
                          'Dark Mode',
                          Icons.dark_mode_outlined,
                          () {
                            // TODO: Implement dark mode toggle
                          },
                        ),
                        _buildProfileTile(
                          'Privacy Policy',
                          Icons.privacy_tip_outlined,
                          () {
                            // TODO: Show privacy policy
                          },
                        ),
                      ]),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _deleteAccount(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Delete Account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
