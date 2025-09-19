import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  bool _canChangeClass = true;

  final List<String> _programs = ['B.Tech', 'M.Tech'];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _departments = ['CSE1','CSE2', 'ECE', 'EE', 'ME', 'AE', 'AIDS','CE'];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
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
        _initialRollNumber = userData['rollNumber'] ?? '';

        _nameController.text = _initialName;
        _emailController.text = _initialEmail;
        _rollNumberController.text = _initialRollNumber;

        // Check if values from database exist in dropdown lists
        _initialProgram = _programs.contains(userData['program']) ? userData['program'] : null;
        _initialDepartment = _departments.contains(userData['department']) ? userData['department'] : null;
        _initialYear = _years.contains(userData['year']) ? userData['year'] : null;

        final joinedClasses = userData['joinedClasses'] as Map<dynamic, dynamic>?;
        _canChangeClass = (joinedClasses == null || joinedClasses.isEmpty);

      }
    } catch (e) {
      print("Error fetching student data: $e");
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
        'rollNumber': _rollNumberController.text.trim(),
        'program': _initialProgram,
        'department': _initialDepartment,
        'year': _initialYear,
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
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      Fluttertoast.showToast(msg: "Password reset link sent to your email!");
    } catch (e) {
      print("Error sending password reset email: $e");
      Fluttertoast.showToast(msg: "Failed to send password reset email.");
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
                        controller: _rollNumberController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Roll Number',
                          prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Roll Number cannot be empty';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _initialProgram,
                        items: _programs.map((program) => DropdownMenuItem(value: program, child: Text(program))).toList(),
                        onChanged: _canChangeClass && _isEditing ? (value) {
                          setState(() {
                            _initialProgram = value;
                          });
                        } : null,
                        decoration: InputDecoration(
                          labelText: 'Program',
                          prefixIcon: const Icon(Icons.school, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: _canChangeClass ? null : Colors.grey[200],
                          filled: !_canChangeClass,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _initialDepartment,
                        items: _departments.map((department) => DropdownMenuItem(value: department, child: Text(department))).toList(),
                        onChanged: _canChangeClass && _isEditing ? (value) {
                          setState(() {
                            _initialDepartment = value;
                          });
                        } : null,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          prefixIcon: const Icon(Icons.business, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: _canChangeClass ? null : Colors.grey[200],
                          filled: !_canChangeClass,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _initialYear,
                        items: _years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                        onChanged: _canChangeClass && _isEditing ? (value) {
                          setState(() {
                            _initialYear = value;
                          });
                        } : null,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3C3E52)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: _canChangeClass ? null : Colors.grey[200],
                          filled: !_canChangeClass,
                        ),
                      ),
                      if (!_canChangeClass)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            "You cannot change your program, department, or year while enrolled in a class.",
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 12,
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
