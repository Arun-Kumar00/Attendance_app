// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'more_info.dart';
// import 'dart:async';
//
// class ViewClassesScreen extends StatefulWidget {
//   const ViewClassesScreen({super.key});
//
//   @override
//   _ViewClassesScreenState createState() => _ViewClassesScreenState();
// }
//
// class _ViewClassesScreenState extends State<ViewClassesScreen> {
//   List<Map<String, dynamic>> _classes = [];
//   bool _isLoading = true;
//   String? _teacherUid;
//   StreamSubscription? _classesSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchClasses();
//   }
//
//   @override
//   void dispose() {
//     _classesSubscription?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _fetchClasses() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//       return;
//     }
//
//     _teacherUid = user.uid;
//     final DatabaseReference userClassesRef = FirebaseDatabase.instance.ref('classes/${user.uid}');
//
//     _classesSubscription = userClassesRef.onValue.listen((event) async {
//       if (!mounted) return;
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       if (data != null) {
//         List<Map<String, dynamic>> loadedClasses = [];
//         for (var classId in data.keys) {
//           final classData = Map<String, dynamic>.from(data[classId]);
//           int studentCount = (classData['joinedStudents'] as Map?)?.length ?? 0;
//           loadedClasses.add({
//             'classId': classId,
//             'department': classData['department'] ?? '',
//             'password': classData['password'] ?? '',
//             'subjectName': classData['subjectName'] ?? '',
//             'teacherName': classData['teacherName'] ?? '',
//             'studentCount': studentCount,
//           });
//         }
//         setState(() {
//           _classes = loadedClasses;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _classes = [];
//           _isLoading = false;
//         });
//       }
//     });
//   }
//
//   void _showDeleteConfirmation(String classId) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           "Confirm Deletion",
//           style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
//         ),
//         content: Text(
//           "Are you sure you want to delete the class '$classId'? This action cannot be undone.",
//           style: GoogleFonts.poppins(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(
//               "Cancel",
//               style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _deleteClass(classId);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade700,
//               foregroundColor: Colors.white,
//             ),
//             child: Text(
//               "Delete",
//               style: GoogleFonts.poppins(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _deleteClass(String classId) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not logged in.");
//       }
//
//       final DatabaseReference classRef = FirebaseDatabase.instance.ref('classes/${user.uid}/$classId');
//       await classRef.remove();
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Class '$classId' deleted successfully!",
//             style: GoogleFonts.poppins(),
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (error) {
//       print("Error deleting class: $error");
//       if (!mounted) return;
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(
//             "Error",
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
//           ),
//           content: Text(
//             "Failed to delete class. Please try again.",
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text(
//                 "OK",
//                 style: GoogleFonts.poppins(color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'My Classes',
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
//           : _classes.isEmpty
//           ? const Center(
//         child: Padding(
//           padding: EdgeInsets.all(24.0),
//           child: Text(
//             "You haven't created any classes yet.",
//             style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: _classes.length,
//         itemBuilder: (context, index) {
//           final classData = _classes[index];
//           return Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             margin: const EdgeInsets.only(bottom: 16),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.school, color: Color(0xFF3C3E52)),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           "${classData['subjectName']}",
//                           style: GoogleFonts.poppins(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: const Color(0xFF3C3E52),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 20, thickness: 1),
//                   _buildInfoRow(context, Icons.fingerprint, "Class ID:", classData['classId']!),
//                   _buildInfoRow(context, Icons.lock, "Password:", classData['password']!),
//                   _buildInfoRow(context, Icons.person, "Teacher:", classData['teacherName']!),
//                   _buildInfoRow(context, Icons.group, "Students:", classData['studentCount'].toString()),
//                   _buildInfoRow(context, Icons.business, "Department:", classData['department']!),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => MoreInfoPage(
//                                 classId: classData['classId']!,
//                                 teacherUid: _teacherUid!,
//                               ),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.info_outline),
//                         label: Text(
//                           "More Info",
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF3C3E52),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () => _showDeleteConfirmation(classData['classId']!),
//                         icon: const Icon(Icons.delete_forever),
//                         label: Text(
//                           "Delete",
//                           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red.shade700,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
//
//   Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: const Color(0xFF6A798C)),
//           const SizedBox(width: 10),
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: const Color(0xFF3C3E52),
//             ),
//           ),
//           const SizedBox(width: 5),
//           Expanded(
//             child: Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 color: const Color(0xFF6A798C),
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
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
  StreamSubscription? _createdClassesSubscription;
  Map<String, StreamSubscription> _classSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    _createdClassesSubscription?.cancel();
    for (var subscription in _classSubscriptions.values) {
      subscription.cancel();
    }
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
    final db = FirebaseDatabase.instance.ref();

    // 🔥 STEP 1: Listen to teacher's created classes list (NEW: from users node)
    final createdClassesRef = db.child('users/$_teacherUid/createdClasses');

    _createdClassesSubscription = createdClassesRef.onValue.listen((event) {
      if (!mounted) return;

      // Cancel all previous class subscriptions
      for (var subscription in _classSubscriptions.values) {
        subscription.cancel();
      }
      _classSubscriptions.clear();

      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        setState(() {
          _classes = [];
          _isLoading = false;
        });
        return;
      }

      // 🔥 STEP 2: Listen to each class individually for real-time updates
      List<Map<String, dynamic>> loadedClasses = [];
      int loadedCount = 0;
      final totalClasses = data.keys.length;

      for (var classId in data.keys) {
        // Listen to class details (NEW: Direct path, no teacher nesting!)
        final classRef = db.child('classes/$classId');

        _classSubscriptions[classId.toString()] = classRef.onValue.listen((classEvent) {
          if (!mounted) return;

          if (classEvent.snapshot.exists) {
            final classData = Map<String, dynamic>.from(
                (classEvent.snapshot.value as Map).cast<Object?, Object?>()
            );

            // Update or add this class to the list
            final existingIndex = loadedClasses.indexWhere(
                    (c) => c['classId'] == classId
            );

            final classMap = {
              'classId': classId.toString(),
              'department': classData['department'] ?? 'N/A',
              'password': classData['password'] ?? '',
              'subjectName': classData['subjectName'] ?? 'Unknown',
              'teacherName': classData['teacherName'] ?? '',
              'studentCount': classData['studentCount'] ?? 0,
              'portalOpen': classData['portalOpen'] ?? false,
              'currentSessionId': classData['currentSessionId'],
              'createdAt': classData['createdAt'],
            };

            if (existingIndex >= 0) {
              loadedClasses[existingIndex] = classMap;
            } else {
              loadedClasses.add(classMap);
              loadedCount++;
            }

            // Update UI when all classes are loaded
            if (loadedCount == totalClasses && mounted) {
              setState(() {
                _classes = loadedClasses;
                _isLoading = false;
              });
            }
          }
        });
      }
    });

    print('✅ Listening to teacher\'s classes');
    print('💰 Cost: Real-time updates with minimal data transfer');
  }

  void _showDeleteConfirmation(String classId, String subjectName) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Text(
              "Confirm Deletion",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete this class?",
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
            const SizedBox(height: 12),
            Text(
              "⚠️ This will delete:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 6),
            _buildWarningItem("All attendance records"),
            _buildWarningItem("All sessions"),
            _buildWarningItem("Student enrollment data"),
            const SizedBox(height: 8),
            Text(
              "This action cannot be undone!",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                color: const Color(0xFF6A798C),
                fontWeight: FontWeight.bold,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Delete Class",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.close, size: 14, color: Colors.red.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red.shade700,
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

      final db = FirebaseDatabase.instance.ref();

      // 🔥 CRITICAL: Delete from ALL locations in the optimized structure
      final updates = <String, dynamic>{
        // Remove main class record
        'classes/$classId': null,

        // Remove from teacher's created classes
        'users/${user.uid}/createdClasses/$classId': null,

        // Remove all class members
        'classMembers/$classId': null,

        // Remove all sessions
        'sessions/$classId': null,

        // Remove all attendance records
        'attendance/$classId': null,

        // Remove class stats
        'classStats/$classId': null,
      };

      // Note: Student attendance records are kept in studentAttendance node
      // for historical purposes. Students can still see their past attendance.

      await db.update(updates);

      print('✅ Class deleted: $classId');
      print('🗑️ Cleaned up from 6 locations');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "Class '$classId' deleted successfully!",
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (error) {
      print("❌ Error deleting class: $error");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
            "Failed to delete class. Please try again.\n\nError: ${error.toString()}",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchClasses,
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
          : _classes.isEmpty
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
                "You haven't created any classes yet.\nTap the '+' button to create your first class!",
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
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final classData = _classes[index];
          final hasActiveSession = classData['currentSessionId'] != null;

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
                          color: Color(0xFF3C3E52),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classData['subjectName'],
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3C3E52),
                              ),
                            ),
                            Text(
                              classData['classId'],
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
                            horizontal: 10,
                            vertical: 6,
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
                  const Divider(height: 24, thickness: 1),

                  // Class details
                  _buildInfoRow(
                    context,
                    Icons.lock,
                    "Password:",
                    classData['password'],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.person,
                    "Teacher:",
                    classData['teacherName'],
                  ),
                  _buildInfoRow(
                    context,
                    Icons.group,
                    "Students:",
                    '${classData['studentCount']} enrolled',
                  ),
                  _buildInfoRow(
                    context,
                    Icons.business,
                    "Department:",
                    classData['department'],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
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
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: Text(
                            "More Info",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3C3E52),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmation(
                            classData['classId']!,
                            classData['subjectName']!,
                          ),
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: Text(
                            "Delete",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6A798C)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C3E52),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
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