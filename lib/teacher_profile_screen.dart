// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// class TeacherProfileScreen extends StatefulWidget {
//   const TeacherProfileScreen({super.key});
//
//   @override
//   State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
// }
//
// class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _genderController = TextEditingController();
//
//   bool _isEditing = false;
//   bool _isLoading = true;
//   String _initialName = '';
//   String _initialEmail = '';
//   String _initialGender = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchTeacherData();
//   }
//
//   Future<void> _fetchTeacherData() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       if (mounted) {
//         Fluttertoast.showToast(msg: "User not logged in.");
//         Navigator.pop(context);
//       }
//       return;
//     }
//
//     try {
//       final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
//       final snapshot = await userRef.get();
//
//       if (snapshot.exists) {
//         final userData = Map<String, dynamic>.from(snapshot.value as Map);
//         _initialName = userData['name'] ?? '';
//         _initialEmail = userData['email'] ?? '';
//         _initialGender = userData['gender'] ?? '';
//
//         _nameController.text = _initialName;
//         _emailController.text = _initialEmail;
//         _genderController.text = _initialGender;
//       }
//     } catch (e) {
//       print("Error fetching teacher data: $e");
//       Fluttertoast.showToast(msg: "Failed to load profile data.");
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       if (mounted) {
//         Fluttertoast.showToast(msg: "User not logged in.");
//         Navigator.pop(context);
//       }
//       return;
//     }
//
//     try {
//       final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
//       await userRef.update({
//         'name': _nameController.text.trim(),
//         'gender': _genderController.text.trim(),
//       });
//
//       if (!mounted) return;
//       Fluttertoast.showToast(msg: "Profile updated successfully!");
//       setState(() => _isEditing = false);
//     } catch (e) {
//       print("Error updating profile: $e");
//       Fluttertoast.showToast(msg: "Failed to update profile.");
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _changePassword() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       if (mounted) {
//         Fluttertoast.showToast(msg: "User not logged in.");
//       }
//       return;
//     }
//
//     try {
//       if (!mounted) return;
//       setState(() => _isLoading = true);
//
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
//
//       if (!mounted) return;
//       Fluttertoast.showToast(msg: "Password reset link sent to your email!");
//     } catch (e) {
//       print("Error sending password reset email: $e");
//       Fluttertoast.showToast(msg: "Failed to send password reset email.");
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'My Profile',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//         actions: [
//           if (!_isEditing)
//             IconButton(
//               icon: const Icon(Icons.edit, color: Colors.white),
//               onPressed: () {
//                 setState(() => _isEditing = true);
//               },
//               tooltip: 'Edit Profile',
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.check, color: Colors.white),
//               onPressed: _updateProfile,
//               tooltip: 'Save Changes',
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 color: Colors.white,
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       TextFormField(
//                         controller: _nameController,
//                         enabled: _isEditing,
//                         decoration: InputDecoration(
//                           labelText: 'Full Name',
//                           prefixIcon: const Icon(Icons.person, color: Color(0xFF3C3E52)),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) return 'Name cannot be empty';
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       TextFormField(
//                         controller: _emailController,
//                         enabled: false, // Email is not editable
//                         decoration: InputDecoration(
//                           labelText: 'Email Address',
//                           prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       TextFormField(
//                         controller: _genderController,
//                         enabled: _isEditing,
//                         decoration: InputDecoration(
//                           labelText: 'Gender',
//                           prefixIcon: const Icon(Icons.transgender, color: Color(0xFF3C3E52)),
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) return 'Gender cannot be empty';
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 30),
//                       ElevatedButton.icon(
//                         onPressed: _changePassword,
//                         icon: const Icon(Icons.lock_reset, color: Colors.white),
//                         label: Text(
//                           'Change Password',
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF6A798C),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           elevation: 5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
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
  final _genderController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  String _initialName = '';
  String _initialEmail = '';
  String _initialGender = '';
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Fluttertoast.showToast(msg: "User not logged in.");
        Navigator.pop(context);
      }
      return;
    }

    try {
      final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        _initialName = userData['name'] ?? '';
        _initialEmail = userData['email'] ?? '';
        _initialGender = userData['gender'] ?? '';
        _profileImageBase64 = userData['profileImageBase64'];

        _nameController.text = _initialName;
        _emailController.text = _initialEmail;
        _genderController.text = _initialGender;
      }
    } catch (e) {
      print("Error fetching teacher data: $e");
      Fluttertoast.showToast(msg: "Failed to load profile data.");
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
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Fluttertoast.showToast(msg: "User not logged in.");
        Navigator.pop(context);
      }
      return;
    }

    try {
      final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
      await userRef.update({
        'name': _nameController.text.trim(),
        'gender': _genderController.text.trim(),
      });

      if (!mounted) return;
      Fluttertoast.showToast(msg: "Profile updated successfully!");
      setState(() => _isEditing = false);
    } catch (e) {
      print("Error updating profile: $e");
      Fluttertoast.showToast(msg: "Failed to update profile.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Fluttertoast.showToast(msg: "User not logged in.");
      }
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      if (!mounted) return;
      Fluttertoast.showToast(msg: "Password reset link sent to your email!");
    } catch (e) {
      print("Error sending password reset email: $e");
      Fluttertoast.showToast(msg: "Failed to send password reset email.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImageAndSave() async {
    if (!mounted) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);
      await userRef.update({'profileImageBase64': base64Image});

      if (!mounted) return;
      setState(() {
        _profileImageBase64 = base64Image;
      });
      Fluttertoast.showToast(msg: "Profile picture updated successfully!");
    } catch (e) {
      print("Error uploading image: $e");
      Fluttertoast.showToast(msg: "Failed to upload image. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _updateProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF6A798C),
                    backgroundImage: _profileImageBase64 != null
                        ? MemoryImage(base64Decode(_profileImageBase64!))
                        : null,
                    child: _profileImageBase64 == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF3C3E52)),
                        onPressed: _pickImageAndSave,
                        tooltip: 'Change Profile Picture',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
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
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Name cannot be empty';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        enabled: false, // Email is not editable
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _genderController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.transgender, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Gender cannot be empty';
                          return null;
                        },
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
                          elevation: 5,
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
}

