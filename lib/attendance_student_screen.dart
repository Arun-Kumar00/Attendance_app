import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String teacherUid;

  const AttendanceScreen({required this.classId, required this.teacherUid, Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _status = "Checking session status...";
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentSessionId();
  }

  Future<void> _fetchCurrentSessionId() async {
    final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey('currentSessionId')) {
        setState(() {
          _currentSessionId = data['currentSessionId'];
          _status = "Session Active";
        });
      } else {
        setState(() {
          _currentSessionId = null;
          _status = "No Active Session";
        });
      }
    });
  }

  Future<void> markAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in.");
      return;
    }
    if (_currentSessionId == null) {
      Fluttertoast.showToast(msg: "No active session.");
      return;
    }
    if (!mounted) return;
    setState(() => _status = "Checking location...");

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Location services are disabled. Please enable them.');
        if (!mounted) return;
        setState(() => _status = "Location services disabled");
        return;
      }

      // Request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: "Location permissions denied.");
          if (!mounted) return;
          setState(() => _status = "Permissions Denied");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: "Location permissions are permanently denied.");
        if (!mounted) return;
        setState(() => _status = "Permissions Denied");
        return;
      }

      // Step 1: GPS Proximity Check
      Position studentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final classRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
      final sessionRef = classRef.child('attendance').child(DateTime.now().toIso8601String().split('T').first).child(_currentSessionId!);
      final sessionSnapshot = await sessionRef.get();

      if (!sessionSnapshot.exists) {
        Fluttertoast.showToast(msg: "Active session not found in database.");
        if (!mounted) return;
        setState(() => _status = "Session Not Found");
        return;
      }

      final teacherLat = sessionSnapshot.child('teacherLat').value as double?;
      final teacherLon = sessionSnapshot.child('teacherLon').value as double?;

      if (teacherLat == null || teacherLon == null) {
        Fluttertoast.showToast(msg: "Teacher's location not available.");
        if (!mounted) return;
        setState(() => _status = "Location Unavailable");
        return;
      }

      double distanceInMeters = Geolocator.distanceBetween(
        studentLocation.latitude,
        studentLocation.longitude,
        teacherLat,
        teacherLon,
      );

      if (distanceInMeters > 20) {
        Fluttertoast.showToast(msg: "You are not within the required 60m radius.");
        if (!mounted) return;
        setState(() => _status = "Out of Range");
        return;
      }

      // Step 2: Mark Attendance in Database
      final studentUid = user.uid;
      final studentAttendanceSnap = await sessionRef.child(studentUid).get();
      if (studentAttendanceSnap.exists) {
        Fluttertoast.showToast(msg: "Attendance already marked.");
        if (!mounted) return;
        setState(() => _status = "Already Marked");
        return;
      }

      await sessionRef.child(studentUid).set("Present");
      Fluttertoast.showToast(msg: "Attendance marked as Present");
      if (!mounted) return;
      setState(() => _status = "Attendance Marked");

    } catch (e) {
      Fluttertoast.showToast(msg: "Error marking attendance: $e");
      if (!mounted) return;
      setState(() => _status = "Error Occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(
            title: Text("Attendance", style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF3C3E52),
            foregroundColor: Colors.white,
          ),
          body: const Center(child: Text("User not logged in.")));
    }

    final studentUid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          "Attendance",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('users/$studentUid').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3C3E52)));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Failed to load user data",
                style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
              ),
            );
          }

          final userData = Map<String, dynamic>.from(snapshot.data!.value as Map);
          final rollNumber = userData['rollNumber'] ?? "N/A";

          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance').get(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF3C3E52)));
              }

              final attendanceData = Map<String, dynamic>.from(attendanceSnapshot.data?.value as Map? ?? {});
              int total = 0, present = 0;

              attendanceData.forEach((date, sessions) {
                if (sessions is Map) {
                  sessions.forEach((sessionId, studentMap) {
                    if (sessionId == "initialized") return;
                    if (studentMap is Map && studentMap.containsKey(studentUid)) {
                      total++;
                      if (studentMap[studentUid] == "Present") present++;
                    }
                  });
                }
              });

              double percent = total > 0 ? present / total : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Class ID: ${widget.classId}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Roll No: $rollNumber",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Current Session: ${_currentSessionId != null ? 'Active' : 'Inactive'}",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: _currentSessionId != null ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Status: $_status",
                              style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: CircularPercentIndicator(
                        radius: 100,
                        lineWidth: 13,
                        percent: percent,
                        animation: true,
                        animationDuration: 1200,
                        curve: Curves.easeInOut,
                        center: Text(
                          "${(percent * 100).toStringAsFixed(1)}%",
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            "Attendance Percentage",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        progressColor: const Color(0xFF3C3E52),
                        backgroundColor: const Color(0xFF6A798C).withOpacity(0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _currentSessionId != null ? markAttendance : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentSessionId != null ? const Color(0xFF3C3E52) : const Color(0xFF6A798C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: Text(
                        _currentSessionId != null ? "Mark Attendance" : "No Session Active",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Attendance Records",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(height: 24),
                    ...attendanceData.entries.map((entry) {
                      final date = entry.key;
                      final sessions = Map<String, dynamic>.from(entry.value);
                      final hasRecord = sessions.entries.where((e) => e.key != 'initialized' && (e.value as Map).containsKey(studentUid)).isNotEmpty;

                      if (!hasRecord) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF3C3E52)),
                              ),
                              const SizedBox(height: 10),
                              ...sessions.entries.where((e) => e.key != 'initialized').map((e) {
                                final studentMap = Map<String, dynamic>.from(e.value);
                                final status = studentMap[studentUid] ?? "N/A";

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Session: ${e.key}",
                                          style: GoogleFonts.poppins(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        status,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: status == "Present" ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}