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
      final usersSnapshot = await FirebaseDatabase.instance.ref('users').get();
      final attendanceRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance');
      final attendanceSnapshot = await attendanceRef.get();

      final List<Map<String, dynamic>> studentsList = [];

      for (var userSnap in usersSnapshot.children) {
        final userData = userSnap.value as Map<dynamic, dynamic>;
        final classKey = '${widget.teacherUid} ${widget.classId}';

        if (userData['role'] == 'student' && (userData['joinedClasses'] ?? {}).containsKey(classKey)) {
          final userId = userSnap.key!;
          final name = userData['name'] ?? '';

          int present = 0, total = 0;

          if (attendanceSnapshot.exists) {
            for (var dateSnap in attendanceSnapshot.children) {
              for (var session in dateSnap.children) {
                if (session.key == "initialized") continue;
                final sessionData = (session.value as Map?) ?? {};
                if (sessionData.containsKey(userId)) {
                  total++;
                  if (sessionData[userId] == "Present") present++;
                }
              }
            }
          }

          double attendancePercentage = total > 0 ? (present / total) * 100 : 0;

          studentsList.add({
            "name": name,
            "percent": attendancePercentage,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _students = studentsList;
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching attendance data: $error");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attendance data. Please try again.';
      });
    }
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
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
          ),
        ),
      )
          : _students.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No student attendance data found for this class.",
            style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final double attendancePercentage = student['percent'];
          final Color progressColor = attendancePercentage >= 75
              ? Colors.green
              : attendancePercentage >= 50
              ? Colors.orange
              : Colors.red;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                student['name'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                "Attendance: ${attendancePercentage.toStringAsFixed(1)}%",
                style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
              ),
              trailing: CircularPercentIndicator(
                radius: 30.0,
                lineWidth: 5.0,
                percent: attendancePercentage / 100,
                center: Text(
                  "${attendancePercentage.toStringAsFixed(0)}%",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                progressColor: progressColor,
                backgroundColor: const Color(0xFFE0E0E0),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  );
                },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text(
                  'Take Attendance',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
            const SizedBox(width: 10),
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF3C3E52)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: const Color(0xFF3C3E52),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
