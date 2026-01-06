import 'dart:async';

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

  const AttendanceScreen({
    required this.classId,
    required this.teacherUid,
    Key? key,
  }) : super(key: key);

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
    // 🔥 NEW: Listen to class directly (no teacher UID nesting!)
    final ref = FirebaseDatabase.instance.ref('classes/${widget.classId}');

    ref.onValue.listen((event) {
      if (!mounted) return;

      final dynamic value = event.snapshot.value;
      final Map<String, dynamic>? data = (value is Map)
          ? Map<String, dynamic>.from(value.cast<Object?, Object?>())
          : null;

      print('--- SESSION ID DEBUG ---');
      print('Path: classes/${widget.classId}');
      print('Data received: ${data != null}');
      print('Key "currentSessionId" exists: ${data?.containsKey('currentSessionId')}');

      String? fetchedSessionId;

      if (data != null && data.containsKey('currentSessionId')) {
        fetchedSessionId = data['currentSessionId'] as String?;
        print('Fetched Session ID: $fetchedSessionId');

        if (mounted) {
          setState(() {
            _currentSessionId = fetchedSessionId;
            _status = fetchedSessionId != null ? "Session Active" : "No Active Session";
          });
        }
      } else {
        print('Fetched Session ID: null');
        if (mounted) {
          setState(() {
            _currentSessionId = null;
            _status = "No Active Session";
          });
        }
      }
      print('--- END DEBUG ---');
    });
  }

  Future<void> markAttendance() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Fluttertoast.showToast(
        msg: "User not logged in.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_currentSessionId == null) {
      Fluttertoast.showToast(
        msg: "No active session.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _status = "Checking location permissions...");

    try {
      // 🔥 STEP 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;

        // Show dialog to guide user to enable location services
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Location Services Disabled',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Please enable Location Services in Settings to mark attendance.\n\n'
                  'Settings → Privacy & Security → Location Services',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3E52),
                ),
                child: Text('Open Settings', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();
        }

        if (!mounted) return;
        setState(() => _status = "Location services disabled");
        return;
      }

      // 🔥 STEP 2: Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();

      print('📍 Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        setState(() => _status = "Requesting location permission...");
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: "Location permission denied. Please enable it to mark attendance.",
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          if (!mounted) return;
          setState(() => _status = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        // Show dialog for permanently denied permission
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Location Permission Required',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Location permission is permanently denied. Please enable it in Settings.\n\n'
                  'Settings → Vidhar → Location → While Using the App',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3E52),
                ),
                child: Text('Open Settings', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await Geolocator.openAppSettings();
        }

        if (!mounted) return;
        setState(() => _status = "Permission permanently denied");
        return;
      }

      // 🔥 STEP 3: Get location with better error handling
      if (!mounted) return;
      setState(() => _status = "Getting your location...");

      Position studentLocation;
      try {
        studentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
      } on TimeoutException {
        Fluttertoast.showToast(
          msg: "Location request timed out. Please try again.",
          backgroundColor: Colors.orange,
        );
        if (!mounted) return;
        setState(() => _status = "Location timeout");
        return;
      } catch (e) {
        print('❌ Error getting location: $e');
        Fluttertoast.showToast(
          msg: "Failed to get location: ${e.toString()}",
          backgroundColor: Colors.red,
        );
        if (!mounted) return;
        setState(() => _status = "Location error");
        return;
      }

      print('✅ Got location: ${studentLocation.latitude}, ${studentLocation.longitude}');
      print('📍 Accuracy: ${studentLocation.accuracy}m');

      // ... rest of your attendance marking code ...

      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final db = FirebaseDatabase.instance.ref();

      // Fetch session data
      final sessionPath = 'sessions/${widget.classId}/$currentDate/$_currentSessionId';
      print('🔍 Fetching session from: $sessionPath');

      final sessionSnapshot = await db.child(sessionPath).get();

      if (!sessionSnapshot.exists) {
        Fluttertoast.showToast(
          msg: "Session not found. It may have expired.",
          backgroundColor: Colors.red,
        );
        if (!mounted) return;
        setState(() => _status = "Session Not Found");
        return;
      }

      final sessionData = Map<String, dynamic>.from(
          (sessionSnapshot.value as Map).cast<Object?, Object?>()
      );

      // Parse teacher coordinates
      final dynamic teacherLatRaw = sessionData['teacherLat'];
      final dynamic teacherLonRaw = sessionData['teacherLon'];

      double? teacherLat = _parseCoordinate(teacherLatRaw);
      double? teacherLon = _parseCoordinate(teacherLonRaw);

      if (teacherLat == null || teacherLon == null) {
        Fluttertoast.showToast(
          msg: "Teacher's location not available.",
          backgroundColor: Colors.red,
        );
        if (!mounted) return;
        setState(() => _status = "Location Unavailable");
        return;
      }

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        studentLocation.latitude,
        studentLocation.longitude,
        teacherLat,
        teacherLon,
      );

      print('📏 Distance: ${distance.toStringAsFixed(2)}m');

      if (distance > 50) {
        Fluttertoast.showToast(
          msg: "Too far! You are ${distance.toStringAsFixed(1)}m away .",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
        if (!mounted) return;
        setState(() => _status = "Out of Range");
        return;
      }

      // Check if already marked
      final attendanceRef = db.child(
          'attendance/${widget.classId}/$currentDate/$_currentSessionId/${user.uid}'
      );

      final existingAttendance = await attendanceRef.get();

      if (existingAttendance.exists) {
        Fluttertoast.showToast(
          msg: "Attendance already marked!",
          backgroundColor: Colors.orange,
        );
        if (!mounted) return;
        setState(() => _status = "Already Marked");
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Mark attendance with batch updates
      final updates = <String, dynamic>{
        'attendance/${widget.classId}/$currentDate/$_currentSessionId/${user.uid}': {
          'status': 'Present',
          'markedAt': timestamp,
          'distance': distance,
        },
        'studentAttendance/${user.uid}/${widget.classId}/sessions/${currentDate}_$_currentSessionId': 'Present',
        'studentAttendance/${user.uid}/${widget.classId}/lastUpdated': timestamp,
      };

      await db.update(updates);

      print('✅ Attendance marked successfully');

      // Update statistics in background
      _updateAttendanceStats(user.uid);

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: "✅ Attendance marked successfully!",
        backgroundColor: Colors.green,
      );
      setState(() => _status = "Attendance Marked");

    } catch (e) {
      print('❌ Error: $e');
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        backgroundColor: Colors.red,
      );
      if (!mounted) return;
      setState(() => _status = "Error Occurred");
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value is String) {
      return double.tryParse(value.trim());
    } else if (value is num) {
      return value.toDouble();
    }
    return null;
  }



  Future<void> _updateAttendanceStats(String studentUid) async {
    try {
      final db = FirebaseDatabase.instance.ref();

      // Get all sessions for this student in this class
      final sessionsSnapshot = await db
          .child('studentAttendance/$studentUid/${widget.classId}/sessions')
          .get();

      if (sessionsSnapshot.exists) {
        final sessions = Map<String, dynamic>.from(
            (sessionsSnapshot.value as Map).cast<Object?, Object?>()
        );

        int total = sessions.length;
        int present = sessions.values.where((v) => v == 'Present').length;
        int absent = total - present;
        double percentage = total > 0 ? (present / total) * 100 : 0;

        // Update stats
        await db.child('studentAttendance/$studentUid/${widget.classId}').update({
          'totalSessions': total,
          'presentCount': present,
          'absentCount': absent,
          'percentage': percentage,
        });

        print('✅ Stats updated: $present/$total = ${percentage.toStringAsFixed(1)}%');
      }
    } catch (e) {
      print('⚠️ Stats update error (non-critical): $e');
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
        body: const Center(child: Text("User not logged in.")),
      );
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3C3E52)),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Failed to load user data",
                style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
              ),
            );
          }

          final dynamic userDataRaw = snapshot.data!.value;

          if (userDataRaw is! Map) {
            return Center(
              child: Text(
                "User data structure is invalid.",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          final userData = Map<String, dynamic>.from(userDataRaw);
          final rollNumber = userData['rollNumber'] ?? "N/A";

          // 🔥 NEW: Get attendance stats from studentAttendance node
          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance
                .ref('studentAttendance/$studentUid/${widget.classId}')
                .get(),
            builder: (context, statsSnapshot) {
              if (statsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3C3E52)),
                );
              }

              int total = 0;
              int present = 0;
              double percent = 0.0;
              Map<String, String> sessions = {};

              if (statsSnapshot.hasData && statsSnapshot.data!.exists) {
                final statsData = Map<String, dynamic>.from(
                    (statsSnapshot.data!.value as Map).cast<Object?, Object?>()
                );

                total = statsData['totalSessions'] ?? 0;
                present = statsData['presentCount'] ?? 0;
                percent = total > 0 ? present / total : 0;

                // Get session details
                if (statsData.containsKey('sessions')) {
                  sessions = Map<String, String>.from(
                      (statsData['sessions'] as Map).cast<String, String>()
                  );
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
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
                                        widget.classId,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: const Color(0xFF3C3E52),
                                        ),
                                      ),
                                      Text(
                                        "Roll No: $rollNumber",
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
                            _buildInfoRow(
                              Icons.circle,
                              "Session Status",
                              _currentSessionId != null ? 'Active' : 'Inactive',
                              color: _currentSessionId != null ? Colors.green : Colors.red,
                            ),
                            _buildInfoRow(
                              Icons.info_outline,
                              "Status",
                              _status,
                            ),
                            _buildInfoRow(
                              Icons.calendar_today,
                              "Total Sessions",
                              total.toString(),
                            ),
                            _buildInfoRow(
                              Icons.check_circle,
                              "Present",
                              present.toString(),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Attendance Percentage
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
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            "Attendance Percentage",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        progressColor: const Color(0xFF3C3E52),
                        backgroundColor: const Color(0xFF6A798C).withOpacity(0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Mark Attendance Button
                    ElevatedButton.icon(
                      onPressed: _currentSessionId != null ? markAttendance : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentSessionId != null
                            ? const Color(0xFF3C3E52)
                            : const Color(0xFF6A798C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: Text(
                        _currentSessionId != null
                            ? "Mark Attendance"
                            : "No Session Active",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Attendance Records
                    Text(
                      "Attendance Records",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(height: 24),

                    if (sessions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            "No attendance records yet",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6A798C),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._buildAttendanceRecords(sessions),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFF6A798C)),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C3E52),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: color ?? const Color(0xFF6A798C),
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttendanceRecords(Map<String, String> sessions) {
    // Group sessions by date
    final Map<String, List<MapEntry<String, String>>> groupedByDate = {};

    for (var entry in sessions.entries) {
      final parts = entry.key.split('_');
      if (parts.length == 2) {
        final date = parts[0];
        if (!groupedByDate.containsKey(date)) {
          groupedByDate[date] = [];
        }
        groupedByDate[date]!.add(entry);
      }
    }

    // Sort dates in reverse (newest first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) {
      final dateSessions = groupedByDate[date]!;

      return Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 10),
              ...dateSessions.map((entry) {
                final sessionId = entry.key.split('_')[1];
                final status = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Session: $sessionId",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == "Present"
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: status == "Present"
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
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
    }).toList();
  }
}