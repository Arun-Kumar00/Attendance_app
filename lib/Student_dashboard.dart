import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Widget? _activeSessionBanner;
  bool _isLoadingBanner = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSessionBanner();
  }

  /// Load active session banner if there are any active sessions
  Future<void> _loadActiveSessionBanner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingBanner = false);
      return;
    }

    final hasActive = await _hasActiveAttendanceSessions(user.uid);

    if (hasActive) {
      final activeSessions = await _getActiveSessionDetails(user.uid);

      if (mounted && activeSessions.isNotEmpty) {
        setState(() {
          _activeSessionBanner = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              border: Border(
                bottom: BorderSide(color: Colors.orange[300]!, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[800], size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Active Attendance Session",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        activeSessions.map((s) => s['subjectName']).join(', '),
                        style: GoogleFonts.poppins(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          _isLoadingBanner = false;
        });
      }
    } else {
      setState(() => _isLoadingBanner = false);
    }
  }

  /// Check if student has any active attendance sessions
  Future<bool> _hasActiveAttendanceSessions(String uid) async {
    try {
      // Get all classes the student has joined
      final userRef = FirebaseDatabase.instance.ref("users/$uid/joinedClasses");
      final joinedClassesSnap = await userRef.get();

      if (!joinedClassesSnap.exists) return false;

      final joinedClasses = Map<String, dynamic>.from(joinedClassesSnap.value as Map);

      // Check each class for active sessions
      for (String classId in joinedClasses.keys) {
        final sessionsRef = FirebaseDatabase.instance.ref("sessions/$classId");
        final sessionsSnap = await sessionsRef.get();

        if (sessionsSnap.exists) {
          final sessionsData = Map<String, dynamic>.from(sessionsSnap.value as Map);

          // Check each date
          for (var dateEntry in sessionsData.entries) {
            if (dateEntry.key == 'initialized') continue;

            final dateSessions = Map<String, dynamic>.from(dateEntry.value as Map);

            // Check each session
            for (var sessionEntry in dateSessions.entries) {
              if (sessionEntry.key == 'initialized') continue;

              final sessionData = Map<String, dynamic>.from(sessionEntry.value as Map);
              final status = sessionData['status'] ?? '';

              // If there's an active session, return true
              if (status == 'active') {
                return true;
              }
            }
          }
        }
      }

      return false; // No active sessions found
    } catch (e) {
      print("Error checking active sessions: $e");
      return false; // On error, allow logout (fail open)
    }
  }

  /// Get active session details for display
  Future<List<Map<String, String>>> _getActiveSessionDetails(String uid) async {
    List<Map<String, String>> activeSessions = [];

    try {
      final userRef = FirebaseDatabase.instance.ref("users/$uid/joinedClasses");
      final joinedClassesSnap = await userRef.get();

      if (!joinedClassesSnap.exists) return activeSessions;

      final joinedClasses = Map<String, dynamic>.from(joinedClassesSnap.value as Map);

      for (String classId in joinedClasses.keys) {
        final sessionsRef = FirebaseDatabase.instance.ref("sessions/$classId");
        final sessionsSnap = await sessionsRef.get();

        if (sessionsSnap.exists) {
          final sessionsData = Map<String, dynamic>.from(sessionsSnap.value as Map);

          for (var dateEntry in sessionsData.entries) {
            if (dateEntry.key == 'initialized') continue;

            final dateSessions = Map<String, dynamic>.from(dateEntry.value as Map);

            for (var sessionEntry in dateSessions.entries) {
              if (sessionEntry.key == 'initialized') continue;

              final sessionData = Map<String, dynamic>.from(sessionEntry.value as Map);
              final status = sessionData['status'] ?? '';

              if (status == 'active') {
                // Get class name
                final classRef = FirebaseDatabase.instance.ref("classes/$classId");
                final classSnap = await classRef.get();

                String subjectName = classId;
                String teacherName = 'Unknown';

                if (classSnap.exists) {
                  final classData = Map<String, dynamic>.from(classSnap.value as Map);
                  subjectName = classData['subjectName'] ?? classId;
                  teacherName = classData['teacherName'] ?? 'Unknown';
                }

                activeSessions.add({
                  'classId': classId,
                  'subjectName': subjectName,
                  'teacherName': teacherName,
                  'sessionId': sessionEntry.key,
                });
              }
            }
          }
        }
      }

      return activeSessions;
    } catch (e) {
      print("Error getting active session details: $e");
      return activeSessions;
    }
  }

  /// Handle logout with active session check
  Future<void> _logout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    try {
      // Check for active sessions
      final hasActive = await _hasActiveAttendanceSessions(uid);

      if (hasActive) {
        // Get active session details
        final activeSessions = await _getActiveSessionDetails(uid);

        // Close loading
        if (mounted) Navigator.pop(context);

        // Show cannot logout dialog
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Row(
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Cannot Logout",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You cannot logout while an attendance session is active.",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (activeSessions.isNotEmpty) ...[
                    Text(
                      "Active Sessions:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...activeSessions.map((session) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Color(0xFF3C3E52)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${session['subjectName']} (${session['teacherName']})",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    "Please wait for the session to end or contact your teacher.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF3C3E52),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return; // Logout blocked
      }

      // No active sessions - show confirmation dialog
      // Close loading first
      if (mounted) Navigator.pop(context);

      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Save lastLogout timestamp
        await FirebaseDatabase.instance
            .ref("users/$uid/lastLogout")
            .set(DateTime.now().millisecondsSinceEpoch);

        // Clear user role from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('role');

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Navigate back to the login screen and remove all previous routes
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
                (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print("Error during logout: $e");

      // Close loading on error
      if (mounted) Navigator.pop(context);

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              "Logout Error",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "An error occurred while logging out. Please try again.",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(color: const Color(0xFF3C3E52)),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/studentProfile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active session banner (if exists)
          if (!_isLoadingBanner && _activeSessionBanner != null)
            _activeSessionBanner!,

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Koala icon at the top
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Image.asset(
                        'assets/Screenshot_2025-08-31_at_15.47.46-removebg-preview.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Welcome message
                  Text(
                    "Welcome, Student!",
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/joinClass');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3C3E52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Join a Class',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/viewJoinedClasses');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A798C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'View Joined Classes',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}