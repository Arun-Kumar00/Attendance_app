import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherPortalScreen extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const TeacherPortalScreen({Key? key, required this.teacherUid, required this.classId}) : super(key: key);

  @override
  State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
}

class _TeacherPortalScreenState extends State<TeacherPortalScreen> {
  String _status = "Loading...";
  Position? _currentLocation;
  String? _currentSessionId;
  bool _isSessionOpen = false;

  Timer? _sessionTimer;
  int _sessionDurationInSeconds = 0;
  DateTime? _sessionStartTime;
  StreamSubscription? _sessionStatusSubscription;
  StreamSubscription? _attendanceCountSubscription;
  int _presentStudentCount = 0;

  @override
  void initState() {
    super.initState();
    _getLocationAndPermissions();
    _listenToSessionStatus();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionStatusSubscription?.cancel();
    _attendanceCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getLocationAndPermissions() async {
    if (!mounted) return;
    setState(() {
      _status = "Checking location permissions...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Location services are disabled. Please enable them.');
        setState(() => _status = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permissions are permanently denied.');
          setState(() => _status = "Location permissions denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'Location permissions are permanently denied, we cannot request permissions.');
        setState(() => _status = "Location permissions permanently denied");
        return;
      }

      _currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _status = "Ready";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
      if (!mounted) return;
      setState(() => _status = "Error getting location");
    }
  }

  void _listenToSessionStatus() {
    final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    _sessionStatusSubscription = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final isOpen = data?['portalOpen'] as bool? ?? false;
      final sessionId = data?['currentSessionId'] as String?;
      final startTimeMillis = data?['sessionStartTime'] as int?;

      setState(() {
        _isSessionOpen = isOpen;
        _currentSessionId = sessionId;
      });

      if (isOpen && startTimeMillis != null) {
        _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        _startTimer();
        _listenToAttendanceCount(sessionId!);
      } else {
        _stopTimer();
        _attendanceCountSubscription?.cancel();
        if (!mounted) return;
        setState(() {
          _presentStudentCount = 0;
        });
      }
    });
  }

  void _listenToAttendanceCount(String sessionId) {
    _attendanceCountSubscription?.cancel();
    final currentDate = DateTime.now().toIso8601String().split('T').first;
    final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance/$currentDate/$sessionId');
    _attendanceCountSubscription = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final count = data.values.where((status) => status == 'Present').length;
        setState(() {
          _presentStudentCount = count;
        });
      }
    });
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_sessionStartTime != null) {
          _sessionDurationInSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
        }
      });
    });
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _sessionDurationInSeconds = 0;
      _sessionStartTime = null;
    });
  }

  Future<void> _refreshStatus() async {
    await _getLocationAndPermissions();
    Fluttertoast.showToast(msg: 'Status refreshed!');
  }

  Future<void> openSession() async {
    if (_currentLocation == null) {
      Fluttertoast.showToast(msg: 'Fetching location, please wait...');
      await _getLocationAndPermissions();
      if (_currentLocation == null) {
        return;
      }
    }

    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');

      await ref.child('attendance/$currentDate/$sessionId').set({
        'initialized': true,
        'teacherLat': _currentLocation!.latitude,
        'teacherLon': _currentLocation!.longitude,
      });

      await ref.update({
        'portalOpen': true,
        'currentSessionId': sessionId,
        'sessionStartTime': DateTime.now().millisecondsSinceEpoch,
      });

      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Session $sessionId opened for $currentDate');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> closeSession() async {
    if (_currentSessionId == null) {
      Fluttertoast.showToast(msg: 'No session is active.');
      return;
    }

    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
      final attendanceSnap = await ref.child('attendance/$currentDate/$_currentSessionId').get();
      final studentSnap = await ref.child('joinedStudents').get();

      if (!attendanceSnap.exists || !studentSnap.exists) {
        Fluttertoast.showToast(msg: 'Missing attendance or student data.');
        return;
      }

      final Map<String, dynamic> attendanceData = Map.from(attendanceSnap.value as Map);
      final Map<String, dynamic> studentData = Map.from(studentSnap.value as Map);

      final recorded = attendanceData.keys.toSet();

      for (final uid in studentData.keys) {
        if (!recorded.contains(uid)) {
          await ref.child('attendance/$currentDate/$_currentSessionId/$uid').set('Absent');
        }
      }

      await ref.update({
        'portalOpen': false,
        'currentSessionId': null,
        'sessionStartTime': null,
      });

      Fluttertoast.showToast(msg: 'Session closed. Absentees marked.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSessionOpen) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Cannot go back',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Please end the current session before leaving this page.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C3E52),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      );
      return false; // Prevent back navigation
    }
    return true; // Allow back navigation
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionActive = _isSessionOpen && _currentSessionId != null;

    return PopScope(
      canPop: !isSessionActive,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F0E8),
        appBar: AppBar(
          title: Text(
            "Teacher Portal",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF3C3E52),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !isSessionActive, // Hide back button if session is active
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshStatus,
              tooltip: "Refresh Status",
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/koala.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Welcome to your portal, teacher!",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C3E52),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Class ID: ${widget.classId}",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C3E52)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Teacher ID: ${widget.teacherUid}",
                        style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF6A798C), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Current Location: ${_currentLocation?.latitude.toStringAsFixed(4) ?? 'N/A'}, ${_currentLocation?.longitude.toStringAsFixed(4) ?? 'N/A'}",
                              style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(isSessionActive ? Icons.check_circle : Icons.cancel, color: isSessionActive ? Colors.green : Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Session Status: ${isSessionActive ? 'Active' : 'Inactive'}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSessionActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (isSessionActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Session ID: $_currentSessionId",
                                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6A798C)),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _formatTime(_sessionDurationInSeconds),
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3C3E52),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: isSessionActive
                    ? const Icon(Icons.refresh, color: Colors.white)
                    : const Icon(Icons.play_circle_fill, color: Colors.white),
                label: Text(
                  isSessionActive ? 'Refresh Status' : 'Start New Session',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: isSessionActive ? _refreshStatus : openSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSessionActive ? const Color(0xFF2E8B57) : const Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock, color: Colors.white),
                label: Text(
                  'End Current Session',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: isSessionActive ? closeSession : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSessionActive ? Colors.red : const Color(0xFF6A798C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
