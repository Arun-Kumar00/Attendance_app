import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'attendance_student_screen.dart'; // Ensure this path is correct

class ViewJoinedClassesScreen extends StatefulWidget {
  const ViewJoinedClassesScreen({super.key});

  @override
  _ViewJoinedClassesScreenState createState() => _ViewJoinedClassesScreenState();
}

class _ViewJoinedClassesScreenState extends State<ViewJoinedClassesScreen> {
  List<Map<String, dynamic>> _joinedClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJoinedClasses();
  }

  Future<void> _fetchJoinedClasses() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final studentUid = user.uid;
      final joinedClassesRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses');

      final joinedClassesSnapshot = await joinedClassesRef.get();

      if (joinedClassesSnapshot.exists) {
        final List<Map<String, dynamic>> fetchedClasses = [];

        for (final classEntry in joinedClassesSnapshot.children) {
          final combinedKey = classEntry.key;
          if (combinedKey == null || !combinedKey.contains(' ')) continue;

          final parts = combinedKey.split(' ');
          final teacherUid = parts[0];
          final classId = parts[1];

          final classSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('classes')
              .child(teacherUid)
              .child(classId)
              .get();

          if (classSnapshot.exists) {
            final classData = Map<String, dynamic>.from(classSnapshot.value as Map);
            fetchedClasses.add({
              'classId': classId,
              'teacherUid': teacherUid,
              'teacherName': classData['teacherName'] ?? 'Unknown',
              'subjectName': classData['subjectName'] ?? 'Unknown',
            });
          }
        }
        if (!mounted) return;
        setState(() {
          _joinedClasses = fetchedClasses;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _joinedClasses = [];
          _isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching joined classes: $error");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _leaveClass(String teacherUid, String classId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final studentUid = user.uid;
      final combinedKey = '$teacherUid $classId';

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child(combinedKey)
          .remove();

      if (!mounted) return;
      setState(() {
        _joinedClasses.removeWhere((element) =>
        element['teacherUid'] == teacherUid && element['classId'] == classId);
      });

      Fluttertoast.showToast(msg: "You have successfully left the class.");
    } catch (error) {
      print("Error leaving class: $error");
      if (!mounted) return;
      Fluttertoast.showToast(msg: "Failed to leave the class. Please try again.");
    }
  }

  void _showLeaveConfirmation(String teacherUid, String classId) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Leave",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to leave the class '$classId'?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF3C3E52))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveClass(teacherUid, classId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("Leave", style: GoogleFonts.poppins()),
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
          'Joined Classes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _joinedClasses.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 150),
              const SizedBox(height: 20),
              Text(
                "You have not joined any classes yet.",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF6A798C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _joinedClasses.length,
        itemBuilder: (context, index) {
          final classData = _joinedClasses[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, size: 30, color: Color(0xFF3C3E52)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          classData['subjectName'] ?? 'Unknown Subject',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3C3E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Class ID: ${classData['classId']}",
                    style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Teacher: ${classData['teacherName']}",
                    style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F0E8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceScreen(
                                teacherUid: classData['teacherUid']!,
                                classId: classData['classId']!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text('Mark Attendance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C3E52),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showLeaveConfirmation(
                          classData['teacherUid']!,
                          classData['classId']!,
                        ),
                        icon: const Icon(Icons.exit_to_app),
                        label: Text('Leave', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A798C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}