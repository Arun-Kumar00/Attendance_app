import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  String _initialName = '';
  String _initialEmail = '';

  String? _profileImageBase64;
  int _createdClassesCount = 0;
  String _teacherUid = '';



  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeacherData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "User not logged in.",
          backgroundColor: Colors.red,
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      _teacherUid = user.uid;
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(
            (snapshot.value as Map).cast<Object?, Object?>()
        );

        _initialName = userData['name'] ?? '';
        _initialEmail = userData['email'] ?? '';

        _profileImageBase64 = userData['profileImageBase64'];

        _nameController.text = _initialName;
        _emailController.text = _initialEmail;

        // 🔥 NEW: Get count of created classes from new structure
        final createdClasses = userData['createdClasses'] as Map<dynamic, dynamic>?;
        _createdClassesCount = createdClasses?.length ?? 0;

        print('✅ Profile loaded: $_initialName');
        print('📚 Created classes: $_createdClassesCount');
      }
    } catch (e) {
      print("❌ Error fetching teacher data: $e");
      Fluttertoast.showToast(
        msg: "Failed to load profile data.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if anything changed




    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "User not logged in.",
          backgroundColor: Colors.red,
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
      };


      await userRef.update(updates);

      print('✅ Profile updated successfully');

      // Update initial values
      _initialName = _nameController.text.trim();

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "✅ Profile updated successfully!",
        backgroundColor: Colors.green,
      );
      setState(() => _isEditing = false);
    } catch (e) {
      print("❌ Error updating profile: $e");
      Fluttertoast.showToast(
        msg: "Failed to update profile.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _deleteAccount() async {
    final TextEditingController confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent.\n\n'
                  'All your data and classes will be deleted.\n\n'
                  'Type DELETE MY ACCOUNT to confirm.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: 'DELETE MY ACCOUNT',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (confirmController.text.trim() == 'DELETE MY ACCOUNT') {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);

      // Delete teacher data
      await FirebaseDatabase.instance.ref('users/${user.uid}').remove();

      // Delete auth account
      await user.delete();

      Fluttertoast.showToast(
        msg: 'Account deleted successfully',
        backgroundColor: Colors.green,
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Re-authentication required. Please log in again.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      Fluttertoast.showToast(
        msg: "User not logged in.",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.mail_outline, color: Color(0xFF3C3E52), size: 28),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'A password reset link will be sent to:\n\n${user.email}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3E52),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Send Link', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "✅ Password reset link sent to ${user.email}",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      print("❌ Error sending password reset email: $e");
      Fluttertoast.showToast(
        msg: "Failed to send password reset email.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImageAndSave() async {
    if (!mounted) return;

    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3C3E52)),
                title: Text('Camera', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF3C3E52)),
                title: Text('Gallery', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    XFile? image;

    try {
      if (source == ImageSource.camera) {
        image = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      } else {
        image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Camera not available on this device.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (image == null) {
      return; // user cancelled or camera unavailable
    }


    if (image == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(
        msg: "User not logged in.",
        backgroundColor: Colors.red,
      );
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final file = File(image.path);
      final bytes = await file.readAsBytes();

      // Check file size (limit to 1MB)
      if (bytes.length > 1024 * 1024) {
        Fluttertoast.showToast(
          msg: "Image too large. Please choose a smaller image.",
          backgroundColor: Colors.orange,
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final base64Image = base64Encode(bytes);

      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      await userRef.update({'profileImageBase64': base64Image});

      print('✅ Profile picture updated');

      if (!mounted) return;
      setState(() {
        _profileImageBase64 = base64Image;
      });
      Fluttertoast.showToast(
        msg: "✅ Profile picture updated!",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print("❌ Error uploading image: $e");
      Fluttertoast.showToast(
        msg: "Failed to upload image. Please try again.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEditing() {
    // Restore original values
    _nameController.text = _initialName;
    setState(() => _isEditing = false);
  }

  void _copyTeacherUid() {
    // You'll need to add clipboard package
    // import 'package:flutter/services.dart';
    // Clipboard.setData(ClipboardData(text: _teacherUid));
    Fluttertoast.showToast(
      msg: "Teacher UID: $_teacherUid\n(Copied to clipboard)",
      backgroundColor: Colors.green,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() => _isEditing = true);
              },
              tooltip: 'Edit Profile',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _cancelEditing,
              tooltip: 'Cancel',
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _updateProfile,
              tooltip: 'Save Changes',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3C3E52),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Picture
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF3C3E52),
                      backgroundImage: _profileImageBase64 != null
                          ? MemoryImage(base64Decode(_profileImageBase64!))
                          : null,
                      child: _profileImageBase64 == null
                          ? Text(
                        _initialName.isNotEmpty
                            ? _initialName[0].toUpperCase()
                            : 'T',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF3C3E52),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _pickImageAndSave,
                        tooltip: 'Change Profile Picture',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Stats Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.school,
                        'Created',
                        '$_createdClassesCount Classes',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFF6A798C).withOpacity(0.3),
                      ),
                      _buildStatItem(
                        Icons.person,
                        'Role',
                        'Teacher',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Teacher UID Card (for students to join classes)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Teacher ID',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _teacherUid,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  color: const Color(0xFF3C3E52),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              onPressed: _copyTeacherUid,
                              tooltip: 'Copy UID',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share this ID with students so they can join your classes',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Profile Form Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Personal Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3C3E52),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF3C3E52),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _isEditing ? null : Colors.grey[100],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF3C3E52),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          suffixIcon: const Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Color(0xFF6A798C),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Change Password',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A798C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _deleteAccount,
                        icon: const Icon(Icons.delete_forever, color: Colors.white),
                        label: Text(
                          'Delete Account',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3C3E52), size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3C3E52),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF6A798C),
          ),
        ),
      ],
    );
  }
}