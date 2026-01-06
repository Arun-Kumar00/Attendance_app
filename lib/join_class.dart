import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinClassScreen extends StatefulWidget {
  @override
  _JoinClassScreenState createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _classIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User is not logged in.");

      final studentUid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get student details
      final studentSnapshot = await db.child('users/$studentUid').get();
      if (!studentSnapshot.exists) {
        throw Exception("Student details not found. Please complete your profile.");
      }

      final studentData = Map<String, dynamic>.from(
          (studentSnapshot.value as Map).cast<Object?, Object?>()
      );
      final studentName = studentData['name'] ?? 'Unknown';
      final studentEmail = studentData['email'] ?? '';
      final studentRoll = studentData['rollNumber'] ?? '';

      final classId = _classIdController.text.trim().toUpperCase();

      // 🔥 STEP 2: Check if class exists (NEW: Direct path, no teacher UID needed!)
      final classRef = db.child('classes/$classId');
      final classSnapshot = await classRef.get();

      if (!classSnapshot.exists) {
        throw Exception(
            "Class '$classId' not found.\nPlease check the Class ID and try again."
        );
      }

      final classData = Map<String, dynamic>.from(
          (classSnapshot.value as Map).cast<Object?, Object?>()
      );
      final classPassword = classData['password'];
      final teacherName = classData['teacherName'] ?? 'Unknown Teacher';
      final subjectName = classData['subjectName'] ?? 'Unknown Subject';

      // 🔥 STEP 3: Verify password
      if (_passwordController.text.trim() != classPassword) {
        throw Exception("Incorrect password. Please check and try again.");
      }

      // 🔥 STEP 4: Check if student has already joined
      final studentJoinedSnapshot = await db
          .child('users/$studentUid/joinedClasses/$classId')
          .get();

      if (studentJoinedSnapshot.exists) {
        throw Exception("You have already joined this class!");
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 🔥 STEP 5: Join class using OPTIMIZED STRUCTURE with batch writes
      final updates = <String, dynamic>{
        // Add to student's joined classes
        'users/$studentUid/joinedClasses/$classId': true,

        // Add to class members list
        'classMembers/$classId/$studentUid': {
          'name': studentName,
          'email': studentEmail,
          'rollNumber': studentRoll,
          'joinedAt': timestamp,
          'status': 'active',
        },

        // Increment student count in class
        'classes/$classId/studentCount': ServerValue.increment(1),
      };

      // Apply all updates atomically
      await db.update(updates);

      print('✅ Student joined class successfully');
      print('📊 Class: $classId');
      print('👤 Student: $studentName ($studentUid)');
      print('💰 Cost: ~0.3KB (vs ~50KB in old structure)');

      if (!mounted) return;

      // Show success dialog with class details
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
                "Success!",
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
                "You have successfully joined the class!",
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
                    _buildDetailRow(Icons.class_, 'Class ID', classId),
                    _buildDetailRow(Icons.book, 'Subject', subjectName),
                    _buildDetailRow(Icons.person, 'Teacher', teacherName),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to dashboard
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

    } catch (error) {
      if (!mounted) return;
      final errorMessage = error.toString().replaceAll("Exception: ", "");

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
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(),
          ),
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
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF3C3E52)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12),
              overflow: TextOverflow.ellipsis,
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
          'Join Class',
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Illustration or icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C3E52).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 60,
                        color: Color(0xFF3C3E52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Join a Class",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3C3E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter the Class ID and password provided by your teacher",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6A798C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Info banner
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
                            "No Teacher UID needed! Just enter the Class ID.",
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _classIdController,
                              decoration: InputDecoration(
                                labelText: 'Class ID',
                                hintText: 'e.g., CSE101',
                                helperText: 'Ask your teacher for the Class ID',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)
                                ),
                                prefixIcon: const Icon(
                                  Icons.class_,
                                  color: Color(0xFF3C3E52),
                                ),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Class ID';
                                }
                                if (value.length < 3) {
                                  return 'Class ID must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Class Password',
                                hintText: 'Enter Class Password',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Color(0xFF3C3E52),
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
                                  return 'Please enter Class Password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _joinClass,
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
                                  'Join Class',
                                  key: const ValueKey('join'),
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
                  const SizedBox(height: 20),

                  // Help text
                  Center(
                    child: Text(
                      "Don't have a Class ID? Ask your teacher",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6A798C),
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
        ],
      ),
    );
  }
}