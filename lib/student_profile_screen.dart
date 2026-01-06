import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNumberController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  String _initialName = '';
  String _initialEmail = '';
  String _initialRollNumber = '';
  String? _initialDepartment;
  String? _initialProgram;
  String? _initialYear;
  String? _profileImageBase64;
  bool _canChangeClass = true;
  int _joinedClassesCount = 0;

  final List<String> _programs = ['B.Tech', 'M.Tech'];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _departments = [
    'CSE1',
    'CSE2',
    'ECE',
    'EE',
    'ME',
    'AE',
    'AIDS',
    'CE',
    'M.Tech(CSE&CSA)'
  ];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
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
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(
            (snapshot.value as Map).cast<Object?, Object?>()
        );

        _initialName = userData['name'] ?? '';
        _initialEmail = userData['email'] ?? '';
        _initialRollNumber = userData['rollNumber'] ?? '';
        _profileImageBase64 = userData['profileImageBase64'];

        _nameController.text = _initialName;
        _emailController.text = _initialEmail;
        _rollNumberController.text = _initialRollNumber;

        _initialProgram = _programs.contains(userData['program'])
            ? userData['program']
            : null;
        _initialDepartment = _departments.contains(userData['department'])
            ? userData['department']
            : null;
        _initialYear = _years.contains(userData['year']) ? userData['year'] : null;

        // 🔥 NEW: Check joined classes from new structure
        final joinedClasses = userData['joinedClasses'] as Map<dynamic, dynamic>?;
        _joinedClassesCount = joinedClasses?.length ?? 0;
        _canChangeClass = _joinedClassesCount == 0;

        print('✅ Profile loaded: $_initialName');
        print('📚 Joined classes: $_joinedClassesCount');
      }
    } catch (e) {
      print("❌ Error fetching student data: $e");
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
    bool hasChanges = _nameController.text.trim() != _initialName ||
        _rollNumberController.text.trim() != _initialRollNumber ||
        _initialProgram != null ||
        _initialDepartment != null ||
        _initialYear != null;

    if (!hasChanges) {
      Fluttertoast.showToast(
        msg: "No changes to save.",
        backgroundColor: Colors.orange,
      );
      setState(() => _isEditing = false);
      return;
    }

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
        'rollNumber': _rollNumberController.text.trim(),
      };

      // Only update if values are selected
      if (_initialProgram != null) updates['program'] = _initialProgram;
      if (_initialDepartment != null) updates['department'] = _initialDepartment;
      if (_initialYear != null) updates['year'] = _initialYear;

      await userRef.update(updates);

      print('✅ Profile updated successfully');

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "✅ Profile updated successfully!",
        backgroundColor: Colors.green,
      );

      // Update initial values
      _initialName = _nameController.text.trim();
      _initialRollNumber = _rollNumberController.text.trim();

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

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
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
                  'All your data will be deleted and cannot be recovered.\n\n'
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

      // 1️⃣ Delete Realtime Database data
      await FirebaseDatabase.instance.ref('users/${user.uid}').remove();

      // 2️⃣ Delete Auth account
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

  Future<void> _pickImageAndUpload() async {
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
        msg: "Camera not available on this device.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (image == null) {
      // user cancelled OR camera unavailable
      return;
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
    _rollNumberController.text = _initialRollNumber;
    setState(() => _isEditing = false);
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
                            : 'S',
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
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickImageAndUpload,
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
                        'Joined',
                        '$_joinedClassesCount Classes',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFF6A798C).withOpacity(0.3),
                      ),
                      _buildStatItem(
                        Icons.person,
                        'Role',
                        'Student',
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
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _rollNumberController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Roll Number',
                          prefixIcon: const Icon(
                            Icons.confirmation_number,
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
                            return 'Roll Number cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Academic Details',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3C3E52),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _initialProgram,
                        items: _programs
                            .map((program) => DropdownMenuItem(
                          value: program,
                          child: Text(program),
                        ))
                            .toList(),
                        onChanged: _canChangeClass && _isEditing
                            ? (value) {
                          setState(() {
                            _initialProgram = value;
                          });
                        }
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Program',
                          prefixIcon: const Icon(
                            Icons.school,
                            color: Color(0xFF3C3E52),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _canChangeClass && _isEditing
                              ? null
                              : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _initialDepartment,
                        items: _departments
                            .map((department) => DropdownMenuItem(
                          value: department,
                          child: Text(department),
                        ))
                            .toList(),
                        onChanged: _canChangeClass && _isEditing
                            ? (value) {
                          setState(() {
                            _initialDepartment = value;
                          });
                        }
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          prefixIcon: const Icon(
                            Icons.business,
                            color: Color(0xFF3C3E52),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _canChangeClass && _isEditing
                              ? null
                              : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _initialYear,
                        items: _years
                            .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        ))
                            .toList(),
                        onChanged: _canChangeClass && _isEditing
                            ? (value) {
                          setState(() {
                            _initialYear = value;
                          });
                        }
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF3C3E52),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _canChangeClass && _isEditing
                              ? null
                              : Colors.grey[100],
                        ),
                      ),

                      if (!_canChangeClass)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Academic details are locked while enrolled in classes.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_reset, color: Colors.white),
                        label: Text(
                          'Change Password',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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