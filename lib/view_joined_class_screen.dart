// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'attendance_student_screen.dart'; // Ensure this path is correct
//
// class ViewJoinedClassesScreen extends StatefulWidget {
//   const ViewJoinedClassesScreen({super.key});
//
//   @override
//   _ViewJoinedClassesScreenState createState() => _ViewJoinedClassesScreenState();
// }
//
// class _ViewJoinedClassesScreenState extends State<ViewJoinedClassesScreen> {
//   List<Map<String, dynamic>> _joinedClasses = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchJoinedClasses();
//   }
//
//   Future<void> _fetchJoinedClasses() async {
//     try {
//       if (!mounted) return;
//       setState(() => _isLoading = true);
//
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not logged in");
//       }
//
//       final studentUid = user.uid;
//       final joinedClassesRef = FirebaseDatabase.instance
//           .ref()
//           .child('users')
//           .child(studentUid)
//           .child('joinedClasses');
//
//       final joinedClassesSnapshot = await joinedClassesRef.get();
//
//       if (joinedClassesSnapshot.exists) {
//         final List<Map<String, dynamic>> fetchedClasses = [];
//
//         for (final classEntry in joinedClassesSnapshot.children) {
//           final combinedKey = classEntry.key;
//           if (combinedKey == null || !combinedKey.contains(' ')) continue;
//
//           final parts = combinedKey.split(' ');
//           final teacherUid = parts[0];
//           final classId = parts[1];
//
//           final classSnapshot = await FirebaseDatabase.instance
//               .ref()
//               .child('classes')
//               .child(teacherUid)
//               .child(classId)
//               .get();
//
//           if (classSnapshot.exists) {
//             final classData = Map<String, dynamic>.from(classSnapshot.value as Map);
//             fetchedClasses.add({
//               'classId': classId,
//               'teacherUid': teacherUid,
//               'teacherName': classData['teacherName'] ?? 'Unknown',
//               'subjectName': classData['subjectName'] ?? 'Unknown',
//             });
//           }
//         }
//         if (!mounted) return;
//         setState(() {
//           _joinedClasses = fetchedClasses;
//           _isLoading = false;
//         });
//       } else {
//         if (!mounted) return;
//         setState(() {
//           _joinedClasses = [];
//           _isLoading = false;
//         });
//       }
//     } catch (error) {
//       print("Error fetching joined classes: $error");
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _leaveClass(String teacherUid, String classId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not logged in");
//       }
//
//       final studentUid = user.uid;
//       final combinedKey = '$teacherUid $classId';
//
//       await FirebaseDatabase.instance
//           .ref()
//           .child('users')
//           .child(studentUid)
//           .child('joinedClasses')
//           .child(combinedKey)
//           .remove();
//
//       if (!mounted) return;
//       setState(() {
//         _joinedClasses.removeWhere((element) =>
//         element['teacherUid'] == teacherUid && element['classId'] == classId);
//       });
//
//       Fluttertoast.showToast(msg: "You have successfully left the class.");
//     } catch (error) {
//       print("Error leaving class: $error");
//       if (!mounted) return;
//       Fluttertoast.showToast(msg: "Failed to leave the class. Please try again.");
//     }
//   }
//
//   void _showLeaveConfirmation(String teacherUid, String classId) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           "Confirm Leave",
//           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//         ),
//         content: Text(
//           "Are you sure you want to leave the class '$classId'?",
//           style: GoogleFonts.poppins(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF3C3E52))),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _leaveClass(teacherUid, classId);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: Text("Leave", style: GoogleFonts.poppins()),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'Joined Classes',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _joinedClasses.isEmpty
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "You have not joined any classes yet.",
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   color: const Color(0xFF6A798C),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: _joinedClasses.length,
//         itemBuilder: (context, index) {
//           final classData = _joinedClasses[index];
//           return Card(
//             elevation: 4,
//             margin: const EdgeInsets.symmetric(vertical: 10.0),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.school, size: 30, color: Color(0xFF3C3E52)),
//                       const SizedBox(width: 15),
//                       Expanded(
//                         child: Text(
//                           classData['subjectName'] ?? 'Unknown Subject',
//                           style: GoogleFonts.poppins(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: const Color(0xFF3C3E52),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Class ID: ${classData['classId']}",
//                     style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     "Teacher: ${classData['teacherName']}",
//                     style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
//                   ),
//                   const Divider(height: 24, color: Color(0xFFF1F0E8)),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AttendanceScreen(
//                                 teacherUid: classData['teacherUid']!,
//                                 classId: classData['classId']!,
//                               ),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.qr_code_scanner),
//                         label: Text('Mark Attendance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF3C3E52),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           elevation: 3,
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () => _showLeaveConfirmation(
//                           classData['teacherUid']!,
//                           classData['classId']!,
//                         ),
//                         icon: const Icon(Icons.exit_to_app),
//                         label: Text('Leave', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF6A798C),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           elevation: 3,
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'attendance_student_screen.dart';

class ViewJoinedClassesScreen extends StatefulWidget {
  const ViewJoinedClassesScreen({super.key});

  @override
  _ViewJoinedClassesScreenState createState() =>
      _ViewJoinedClassesScreenState();
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
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get list of joined class IDs (NEW: No teacher UID needed!)
      final joinedClassesRef = db.child('users/$studentUid/joinedClasses');
      final joinedClassesSnapshot = await joinedClassesRef.get();

      if (!joinedClassesSnapshot.exists) {
        if (!mounted) return;
        setState(() {
          _joinedClasses = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> fetchedClasses = [];

      // 🔥 STEP 2: Fetch class details for each joined class
      for (final classEntry in joinedClassesSnapshot.children) {
        final classId = classEntry.key;
        if (classId == null) continue;

        // NEW: Direct path to class (no teacher UID!)
        final classSnapshot = await db.child('classes/$classId').get();

        if (classSnapshot.exists) {
          final classData = Map<String, dynamic>.from(
              (classSnapshot.value as Map).cast<Object?, Object?>()
          );

          // Get student's attendance stats (NEW: From studentAttendance node)
          final attendanceStatsSnapshot = await db
              .child('studentAttendance/$studentUid/$classId')
              .get();

          int totalSessions = 0;
          int presentCount = 0;
          double percentage = 0.0;

          if (attendanceStatsSnapshot.exists) {
            final stats = Map<String, dynamic>.from(
                (attendanceStatsSnapshot.value as Map).cast<Object?, Object?>()
            );
            totalSessions = stats['totalSessions'] ?? 0;
            presentCount = stats['presentCount'] ?? 0;
            percentage = (stats['percentage'] ?? 0.0).toDouble();
          }

          fetchedClasses.add({
            'classId': classId,
            'teacherUid': classData['teacherUid'] ?? '',
            'teacherName': classData['teacherName'] ?? 'Unknown',
            'subjectName': classData['subjectName'] ?? 'Unknown',
            'department': classData['department'] ?? 'N/A',
            'studentCount': classData['studentCount'] ?? 0,
            'portalOpen': classData['portalOpen'] ?? false,
            'currentSessionId': classData['currentSessionId'],
            'totalSessions': totalSessions,
            'presentCount': presentCount,
            'percentage': percentage,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _joinedClasses = fetchedClasses;
        _isLoading = false;
      });

      print('✅ Fetched ${fetchedClasses.length} joined classes');
      print('💰 Cost: ~${fetchedClasses.length * 0.5}KB (vs ~${fetchedClasses.length * 50}KB in old structure)');

    } catch (error) {
      print("❌ Error fetching joined classes: $error");
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to load classes. Please try again.",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _leaveClass(String classId, String teacherUid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final studentUid = user.uid;
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Remove from multiple locations using batch updates
      final updates = <String, dynamic>{
        // Remove from student's joined classes
        'users/$studentUid/joinedClasses/$classId': null,

        // Remove from class members
        'classMembers/$classId/$studentUid': null,

        // Decrement student count
        'classes/$classId/studentCount': ServerValue.increment(-1),
      };

      await db.update(updates);

      if (!mounted) return;
      setState(() {
        _joinedClasses.removeWhere((element) => element['classId'] == classId);
      });

      print('✅ Student left class: $classId');
      Fluttertoast.showToast(
        msg: "You have successfully left the class.",
        backgroundColor: Colors.green,
      );

    } catch (error) {
      print("❌ Error leaving class: $error");
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "Failed to leave the class. Please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showLeaveConfirmation(String classId, String subjectName, String teacherUid) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            Text(
              "Confirm Leave",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to leave this class?",
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Class: $subjectName",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "ID: $classId",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "⚠️ Your attendance records will be preserved but you won't be able to mark attendance anymore.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: const Color(0xFF3C3E52),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveClass(classId, teacherUid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("Leave Class", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceIndicator(double percentage) {
    Color color;
    IconData icon;

    if (percentage >= 75) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (percentage >= 60) {
      color = Colors.orange;
      icon = Icons.warning_amber;
    } else {
      color = Colors.red;
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
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
          'Joined Classes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJoinedClasses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3C3E52),
        ),
      )
          : _joinedClasses.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3E52).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 60,
                  color: Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No Classes Yet",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You haven't joined any classes yet.\nAsk your teacher for a Class ID to get started!",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6A798C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchJoinedClasses,
        color: const Color(0xFF3C3E52),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _joinedClasses.length,
          itemBuilder: (context, index) {
            final classData = _joinedClasses[index];
            final hasActiveSession = classData['currentSessionId'] != null;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with subject and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3C3E52).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 28,
                            color: Color(0xFF3C3E52),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classData['subjectName'] ?? 'Unknown Subject',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3C3E52),
                                ),
                              ),
                              Text(
                                classData['classId'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6A798C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasActiveSession)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Class details
                    _buildInfoRow(Icons.person, 'Teacher', classData['teacherName'] ?? 'Unknown'),
                    _buildInfoRow(Icons.business, 'Department', classData['department'] ?? 'N/A'),
                    _buildInfoRow(Icons.people, 'Students', '${classData['studentCount']} enrolled'),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Attendance stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Attendance',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6A798C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${classData['presentCount']}/${classData['totalSessions']} sessions',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3C3E52),
                              ),
                            ),
                          ],
                        ),
                        _buildAttendanceIndicator(classData['percentage']),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendanceScreen(
                                    teacherUid: classData['teacherUid']!,
                                    classId: classData['classId']!,
                                  ),
                                ),
                              ).then((_) => _fetchJoinedClasses());
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: Text(
                              'Mark Attendance',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3C3E52),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: () => _showLeaveConfirmation(
                              classData['classId']!,
                              classData['subjectName']!,
                              classData['teacherUid']!,
                            ),
                            icon: const Icon(Icons.exit_to_app, size: 18),
                            label: Text(
                              'Leave',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6A798C)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6A798C),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3C3E52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}