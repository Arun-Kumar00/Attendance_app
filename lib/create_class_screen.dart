import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subjectNameController = TextEditingController();
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
  String? _selectedDepartment = 'CSE1';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _classIdController.dispose();
    _passwordController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  /// Check if class ID is globally unique
  Future<bool> _isClassIdUnique(String classId) async {
    final classRef = FirebaseDatabase.instance.ref('classes/$classId');
    final snapshot = await classRef.get();
    return !snapshot.exists;
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated.");
      }

      final teacherUid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get teacher details
      final teacherSnapshot = await db.child('users/$teacherUid').get();
      if (!teacherSnapshot.exists) {
        throw Exception("Teacher details not found.");
      }
      final teacherName = teacherSnapshot.child('name').value.toString();

      final classId = _classIdController.text.trim().toUpperCase(); // Uppercase for consistency

      // 🔥 STEP 2: Check if class ID is GLOBALLY unique
      final isUnique = await _isClassIdUnique(classId);
      if (!isUnique) {
        throw Exception(
            "Class ID '$classId' already exists!\nPlease choose a different unique ID."
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 🔥 STEP 3: Create class using NEW OPTIMIZED STRUCTURE
      // Uses batch update to write to multiple locations atomically
      final updates = <String, dynamic>{
        // Main class record (no teacher nesting!)
        'classes/$classId': {
          'classId': classId,
          'subjectName': _subjectNameController.text.trim(),
          'department': _selectedDepartment,
          'teacherUid': teacherUid,
          'teacherName': teacherName,
          'password': _passwordController.text.trim(),
          'portalOpen': false,
          'createdAt': timestamp,
          'studentCount': 0,
          'currentSessionId': null,
        },

        // Add to teacher's created classes list
        'users/$teacherUid/createdClasses/$classId': true,

        // Initialize empty classMembers node (students will be added when they join)hkjhgjhjh
        'classMembers/$classId/initialized': true,
      };

      // 🔥 STEP 4: Apply all updates atomically
      await db.update(updates);

      print('✅ Class created successfully: $classId');
      print('📊 Structure used: Optimized flat structure');
      print('💰 Cost: ~0.5KB write (vs ~50KB in old nested structure)');

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                "Success",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C3E52),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Class has been successfully created!",
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Class Details:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "ID: $classId",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      "Subject: ${_subjectNameController.text.trim()}",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      "Department: $_selectedDepartment",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/teacherDashboard',
                        (route) => false,
                  );
                }
              },
              child: Text(
                "Go to Dashboard",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF3C3E52),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "An authentication error occurred.");
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Text(
              "Error",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'Create Class',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Info banner about unique class IDs
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue.shade700,
                                      size: 20
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Class ID must be globally unique across all teachers",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _classIdController,
                              decoration: InputDecoration(
                                labelText: 'Class ID',
                                hintText: 'e.g., CSE101, MATH2025',
                                helperText: 'Use uppercase for consistency',
                                prefixIcon: const Icon(
                                  Icons.qr_code_2,
                                  color: Color(0xFF3C3E52),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a Class ID';
                                }
                                if (value.length < 3) {
                                  return 'Class ID must be at least 3 characters';
                                }
                                if (value.length > 20) {
                                  return 'Class ID must be less than 20 characters';
                                }
                                // Allow alphanumeric and hyphens/underscores only
                                if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
                                  return 'Only letters, numbers, hyphens and underscores allowed';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Class Password',
                                hintText: 'Enter a secure password',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Color(0xFF3C3E52),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF3C3E52),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectNameController,
                              decoration: InputDecoration(
                                labelText: 'Subject Name',
                                hintText: 'e.g., Data Structures',
                                prefixIcon: const Icon(
                                  Icons.book,
                                  color: Color(0xFF3C3E52),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a subject name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              items: _departments
                                  .map((dep) => DropdownMenuItem(
                                value: dep,
                                child: Text(dep),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Department',
                                prefixIcon: const Icon(
                                  Icons.business,
                                  color: Color(0xFF3C3E52),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a department';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _createClass,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C3E52),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return FadeTransition(
                                      opacity: animation, child: child);
                                },
                                child: _isLoading
                                    ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : Text(
                                  'Create Class',
                                  key: const ValueKey('create_class'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}