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
  final _teacherUidController = TextEditingController();
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _teacherUidController.dispose();
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
      final studentSnapshot = await FirebaseDatabase.instance.ref().child('users').child(studentUid).get();
      if (!studentSnapshot.exists) throw Exception("Student details not found.");

      final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
      final studentName = studentData['name'];
      final studentEmail = studentData['email'];

      final teacherUid = _teacherUidController.text.trim();
      final classId = _classIdController.text.trim();

      final classRef = FirebaseDatabase.instance.ref().child('classes').child(teacherUid).child(classId);
      final classSnapshot = await classRef.get();
      if (!classSnapshot.exists) throw Exception("Class not found.");

      final classData = classSnapshot.value as Map<dynamic, dynamic>;
      final classPassword = classData['password'];

      if (_passwordController.text.trim() != classPassword) throw Exception("Incorrect password.");

      // Check if student has already joined the class
      final combinedKey = '$teacherUid $classId';
      final studentJoinedSnapshot = await FirebaseDatabase.instance.ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child(combinedKey)
          .get();

      if (studentJoinedSnapshot.exists) {
        throw Exception("You have already joined this class.");
      }

      await FirebaseDatabase.instance.ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child(combinedKey)
          .set(true);

      await FirebaseDatabase.instance.ref()
          .child('classes')
          .child(teacherUid)
          .child(classId)
          .child('joinedStudents')
          .child(studentUid)
          .set({
        'name': studentName,
        'email': studentEmail,
      });

      if (!mounted) return;
      Fluttertoast.showToast(msg: "You have successfully joined the class!");
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: error.toString().replaceAll("Exception: ", ""));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100.0),
                    ),
                  ),
                  Text(
                    "Enter Class Details",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C3E52),
                    ),
                    textAlign: TextAlign.center,
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
                              controller: _teacherUidController,
                              decoration: InputDecoration(
                                labelText: 'Teacher UID',
                                hintText: 'Ask your teacher for their UID',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF3C3E52)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Teacher UID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _classIdController,
                              decoration: InputDecoration(
                                labelText: 'Class ID',
                                hintText: 'Enter the Class ID',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.class_, color: Color(0xFF3C3E52)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Class ID';
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: _isLoading
                                    ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
