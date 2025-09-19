import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'more_info.dart';
import 'dart:async';

class ViewClassesScreen extends StatefulWidget {
  const ViewClassesScreen({super.key});

  @override
  _ViewClassesScreenState createState() => _ViewClassesScreenState();
}

class _ViewClassesScreenState extends State<ViewClassesScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _teacherUid;
  StreamSubscription? _classesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    _classesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _teacherUid = user.uid;
    final DatabaseReference userClassesRef = FirebaseDatabase.instance.ref('classes/${user.uid}');

    _classesSubscription = userClassesRef.onValue.listen((event) async {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> loadedClasses = [];
        for (var classId in data.keys) {
          final classData = Map<String, dynamic>.from(data[classId]);
          int studentCount = (classData['joinedStudents'] as Map?)?.length ?? 0;
          loadedClasses.add({
            'classId': classId,
            'department': classData['department'] ?? '',
            'password': classData['password'] ?? '',
            'subjectName': classData['subjectName'] ?? '',
            'teacherName': classData['teacherName'] ?? '',
            'studentCount': studentCount,
          });
        }
        setState(() {
          _classes = loadedClasses;
          _isLoading = false;
        });
      } else {
        setState(() {
          _classes = [];
          _isLoading = false;
        });
      }
    });
  }

  void _showDeleteConfirmation(String classId) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Deletion",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          "Are you sure you want to delete the class '$classId'? This action cannot be undone.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClass(classId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(String classId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final DatabaseReference classRef = FirebaseDatabase.instance.ref('classes/${user.uid}/$classId');
      await classRef.remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Class '$classId' deleted successfully!",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print("Error deleting class: $error");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            "Error",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            "Failed to delete class. Please try again.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'My Classes',
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
          : _classes.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "You haven't created any classes yet.",
            style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final classData = _classes[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, color: Color(0xFF3C3E52)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${classData['subjectName']}",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3C3E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  _buildInfoRow(context, Icons.fingerprint, "Class ID:", classData['classId']!),
                  _buildInfoRow(context, Icons.lock, "Password:", classData['password']!),
                  _buildInfoRow(context, Icons.person, "Teacher:", classData['teacherName']!),
                  _buildInfoRow(context, Icons.group, "Students:", classData['studentCount'].toString()),
                  _buildInfoRow(context, Icons.business, "Department:", classData['department']!),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoreInfoPage(
                                classId: classData['classId']!,
                                teacherUid: _teacherUid!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: Text(
                          "More Info",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C3E52),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmation(classData['classId']!),
                        icon: const Icon(Icons.delete_forever),
                        label: Text(
                          "Delete",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6A798C)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C3E52),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF6A798C),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}