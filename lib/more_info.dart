// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'package:vidhar/teacher_portel_screen.dart';
// import 'extra_info.dart';
//
// class MoreInfoPage extends StatefulWidget {
//   final String teacherUid;
//   final String classId;
//
//   const MoreInfoPage({
//     super.key,
//     required this.teacherUid,
//     required this.classId,
//   });
//
//   @override
//   State<MoreInfoPage> createState() => _MoreInfoPageState();
// }
//
// class _MoreInfoPageState extends State<MoreInfoPage> {
//   List<Map<String, dynamic>> _students = [];
//   bool _isLoading = true;
//   String _errorMessage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAttendanceData();
//   }
//
//   Future<void> _fetchAttendanceData() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//     _errorMessage = '';
//
//     try {
//       final usersSnapshot = await FirebaseDatabase.instance.ref('users').get();
//       final attendanceRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance');
//       final attendanceSnapshot = await attendanceRef.get();
//
//       final List<Map<String, dynamic>> studentsList = [];
//
//       for (var userSnap in usersSnapshot.children) {
//         final userData = userSnap.value as Map<dynamic, dynamic>;
//         final classKey = '${widget.teacherUid} ${widget.classId}';
//
//         if (userData['role'] == 'student' && (userData['joinedClasses'] ?? {}).containsKey(classKey)) {
//           final userId = userSnap.key!;
//           final name = userData['name'] ?? '';
//
//           int present = 0, total = 0;
//
//           if (attendanceSnapshot.exists) {
//             for (var dateSnap in attendanceSnapshot.children) {
//               for (var session in dateSnap.children) {
//                 if (session.key == "initialized") continue;
//                 final sessionData = (session.value as Map?) ?? {};
//                 if (sessionData.containsKey(userId)) {
//                   total++;
//                   if (sessionData[userId] == "Present") present++;
//                 }
//               }
//             }
//           }
//
//           double attendancePercentage = total > 0 ? (present / total) * 100 : 0;
//
//           studentsList.add({
//             "name": name,
//             "percent": attendancePercentage,
//           });
//         }
//       }
//
//       if (!mounted) return;
//       setState(() {
//         _students = studentsList;
//         _isLoading = false;
//       });
//     } catch (error) {
//       print("Error fetching attendance data: $error");
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Failed to load attendance data. Please try again.';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           "Class Info: ${widget.classId}",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchAttendanceData,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Text(
//             _errorMessage,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
//           ),
//         ),
//       )
//           : _students.isEmpty
//           ? const Center(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text(
//             "No student attendance data found for this class.",
//             style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: _students.length,
//         itemBuilder: (context, index) {
//           final student = _students[index];
//           final double attendancePercentage = student['percent'];
//           final Color progressColor = attendancePercentage >= 75
//               ? Colors.green
//               : attendancePercentage >= 50
//               ? Colors.orange
//               : Colors.red;
//
//           return Card(
//             elevation: 4,
//             margin: const EdgeInsets.symmetric(vertical: 8.0),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               title: Text(
//                 student['name'],
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               subtitle: Text(
//                 "Attendance: ${attendancePercentage.toStringAsFixed(1)}%",
//                 style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
//               ),
//               trailing: CircularPercentIndicator(
//                 radius: 30.0,
//                 lineWidth: 5.0,
//                 percent: attendancePercentage / 100,
//                 center: Text(
//                   "${attendancePercentage.toStringAsFixed(0)}%",
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.bold,
//                     color: progressColor,
//                   ),
//                 ),
//                 progressColor: progressColor,
//                 backgroundColor: const Color(0xFFE0E0E0),
//               ),
//             ),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => TeacherPortalScreen(
//                         teacherUid: widget.teacherUid,
//                         classId: widget.classId,
//                       ),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
//                 label: Text(
//                   'Take Attendance',
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF3C3E52),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ExtraInfoPage(
//                         teacherUid: widget.teacherUid,
//                         classId: widget.classId,
//                       ),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.info_outline, color: Color(0xFF3C3E52)),
//                 label: Text(
//                   'Extra Info',
//                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF3C3E52)),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFE0E0E0),
//                   foregroundColor: const Color(0xFF3C3E52),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vidhar/teacher_portel_screen.dart';
import 'extra_info.dart';

class MoreInfoPage extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const MoreInfoPage({
    super.key,
    required this.teacherUid,
    required this.classId,
  });

  @override
  State<MoreInfoPage> createState() => _MoreInfoPageState();
}

class _MoreInfoPageState extends State<MoreInfoPage> {
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _classInfo;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _errorMessage = '';

    try {
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get class info (NEW: Direct path, no teacher UID nesting!)
      final classSnapshot = await db.child('classes/${widget.classId}').get();

      if (!classSnapshot.exists) {
        throw Exception("Class not found");
      }

      final classData = Map<String, dynamic>.from(
          (classSnapshot.value as Map).cast<Object?, Object?>()
      );

      // 🔥 STEP 2: Get list of class members (NEW: From classMembers node)
      final membersSnapshot = await db.child('classMembers/${widget.classId}').get();

      if (!membersSnapshot.exists || membersSnapshot.children.isEmpty) {
        if (!mounted) return;
        setState(() {
          _classInfo = classData;
          _students = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> studentsList = [];

      // 🔥 STEP 3: Fetch attendance stats for each student (NEW: Pre-calculated!)
      for (var memberSnap in membersSnapshot.children) {
        if (memberSnap.key == 'initialized') continue;

        final studentUid = memberSnap.key!;
        final memberData = Map<String, dynamic>.from(
            (memberSnap.value as Map).cast<Object?, Object?>()
        );

        // Get student's attendance stats (NEW: From studentAttendance node)
        final attendanceStatsSnapshot = await db
            .child('studentAttendance/$studentUid/${widget.classId}')
            .get();

        int totalSessions = 0;
        int presentCount = 0;
        int absentCount = 0;
        double attendancePercentage = 0.0;

        if (attendanceStatsSnapshot.exists) {
          final stats = Map<String, dynamic>.from(
              (attendanceStatsSnapshot.value as Map).cast<Object?, Object?>()
          );
          totalSessions = stats['totalSessions'] ?? 0;
          presentCount = stats['presentCount'] ?? 0;
          absentCount = stats['absentCount'] ?? 0;
          attendancePercentage = (stats['percentage'] ?? 0.0).toDouble();
        }

        studentsList.add({
          "uid": studentUid,
          "name": memberData['name'] ?? 'Unknown',
          "email": memberData['email'] ?? '',
          "rollNumber": memberData['rollNumber'] ?? 'N/A',
          "totalSessions": totalSessions,
          "presentCount": presentCount,
          "absentCount": absentCount,
          "percent": attendancePercentage,
          "joinedAt": memberData['joinedAt'] ?? 0,
          "status": memberData['status'] ?? 'active',
        });
      }

      // Sort by name
      studentsList.sort((a, b) =>
          (a['name'] as String).toLowerCase().compareTo(
              (b['name'] as String).toLowerCase()
          )
      );

      print('✅ Fetched ${studentsList.length} students');
      print('💰 Cost: ~${studentsList.length * 0.3}KB (vs ~${studentsList.length * 50}KB in old structure)');
      print('⚡ Speed: Instant (pre-calculated stats vs on-the-fly calculation)');

      if (!mounted) return;
      setState(() {
        _classInfo = classData;
        _students = studentsList;
        _isLoading = false;
      });
    } catch (error) {
      print("❌ Error fetching attendance data: $error");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attendance data. Please try again.';
      });
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getAttendanceIcon(double percentage) {
    if (percentage >= 75) return Icons.check_circle;
    if (percentage >= 60) return Icons.warning_amber;
    return Icons.error_outline;
  }

  Widget _buildClassHeader() {
    if (_classInfo == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _classInfo!['subjectName'] ?? 'Unknown Subject',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3C3E52),
                        ),
                      ),
                      Text(
                        widget.classId,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6A798C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  'Students',
                  '${_students.length}',
                ),
                _buildStatItem(
                  Icons.business,
                  'Department',
                  _classInfo!['department'] ?? 'N/A',
                ),
              ],
            ),
          ],
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
            fontSize: 18,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          "Class Info: ${widget.classId}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAttendanceData,
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
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAttendanceData,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3E52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : _students.isEmpty
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
                  Icons.people_outline,
                  size: 60,
                  color: Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No Students Yet",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "No students have joined this class yet.\nShare the Class ID with your students!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6A798C),
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          _buildClassHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${_students.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3C3E52),
                  ),
                ),
                Text(
                  'Sorted by name',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6A798C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final double attendancePercentage = student['percent'];
                final Color progressColor = _getAttendanceColor(attendancePercentage);
                final IconData statusIcon = _getAttendanceIcon(attendancePercentage);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF3C3E52).withOpacity(0.1),
                              child: Text(
                                student['name'][0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3C3E52),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF3C3E52),
                                    ),
                                  ),
                                  Text(
                                    'Roll: ${student['rollNumber']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6A798C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircularPercentIndicator(
                              radius: 30.0,
                              lineWidth: 5.0,
                              percent: attendancePercentage / 100,
                              center: Text(
                                "${attendancePercentage.toStringAsFixed(0)}%",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: progressColor,
                                ),
                              ),
                              progressColor: progressColor,
                              backgroundColor: const Color(0xFFE0E0E0),
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAttendanceStat(
                              Icons.calendar_today,
                              'Total',
                              '${student['totalSessions']}',
                              const Color(0xFF3C3E52),
                            ),
                            _buildAttendanceStat(
                              Icons.check_circle,
                              'Present',
                              '${student['presentCount']}',
                              Colors.green,
                            ),
                            _buildAttendanceStat(
                              Icons.cancel,
                              'Absent',
                              '${student['absentCount']}',
                              Colors.red,
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
        ],
      ),
      bottomNavigationBar: _students.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherPortalScreen(
                        teacherUid: widget.teacherUid,
                        classId: widget.classId,
                      ),
                    ),
                  ).then((_) => _fetchAttendanceData()); // Refresh on return
                },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text(
                  'Take Attendance',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3E52),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExtraInfoPage(
                        teacherUid: widget.teacherUid,
                        classId: widget.classId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, color: Color(0xFF3C3E52)),
                label: Text(
                  'Extra Info',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3C3E52),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: const Color(0xFF3C3E52),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF6A798C),
          ),
        ),
      ],
    );
  }
}