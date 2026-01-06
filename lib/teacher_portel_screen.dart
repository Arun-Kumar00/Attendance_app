// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:fluttertoast/fluttertoast.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class TeacherPortalScreen extends StatefulWidget {
// //   final String teacherUid;
// //   final String classId;
// //
// //   const TeacherPortalScreen({Key? key, required this.teacherUid, required this.classId}) : super(key: key);
// //
// //   @override
// //   State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
// // }
// //
// // class _TeacherPortalScreenState extends State<TeacherPortalScreen> {
// //   String _status = "Loading...";
// //   Position? _currentLocation;
// //   String? _currentSessionId;
// //   bool _isSessionOpen = false;
// //
// //   Timer? _sessionTimer;
// //   int _sessionDurationInSeconds = 0;
// //   DateTime? _sessionStartTime;
// //   StreamSubscription? _sessionStatusSubscription;
// //   StreamSubscription? _attendanceCountSubscription;
// //   int _presentStudentCount = 0;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _getLocationAndPermissions();
// //     _listenToSessionStatus();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _sessionTimer?.cancel();
// //     _sessionStatusSubscription?.cancel();
// //     _attendanceCountSubscription?.cancel();
// //     super.dispose();
// //   }
// //
// //   Future<void> _getLocationAndPermissions() async {
// //     if (!mounted) return;
// //     setState(() {
// //       _status = "Checking location permissions...";
// //     });
// //
// //     try {
// //       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //       if (!serviceEnabled) {
// //         Fluttertoast.showToast(msg: 'Location services are disabled. Please enable them.');
// //         setState(() => _status = "Location services disabled");
// //         return;
// //       }
// //
// //       LocationPermission permission = await Geolocator.checkPermission();
// //       if (permission == LocationPermission.denied) {
// //         permission = await Geolocator.requestPermission();
// //         if (permission == LocationPermission.denied) {
// //           Fluttertoast.showToast(msg: 'Location permissions are permanently denied.');
// //           setState(() => _status = "Location permissions denied");
// //           return;
// //         }
// //       }
// //
// //       if (permission == LocationPermission.deniedForever) {
// //         Fluttertoast.showToast(msg: 'Location permissions are permanently denied, we cannot request permissions.');
// //         setState(() => _status = "Location permissions permanently denied");
// //         return;
// //       }
// //
// //       _currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
// //       if (!mounted) return;
// //       setState(() {
// //         _status = "Ready";
// //       });
// //     } catch (e) {
// //       Fluttertoast.showToast(msg: 'Error getting location: $e');
// //       if (!mounted) return;
// //       setState(() => _status = "Error getting location");
// //     }
// //   }
// //
// //   void _listenToSessionStatus() {
// //     final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
// //     _sessionStatusSubscription = ref.onValue.listen((event) {
// //       if (!mounted) return;
// //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
// //       final isOpen = data?['portalOpen'] as bool? ?? false;
// //       final sessionId = data?['currentSessionId'] as String?;
// //       final startTimeMillis = data?['sessionStartTime'] as int?;
// //
// //       setState(() {
// //         _isSessionOpen = isOpen;
// //         _currentSessionId = sessionId;
// //       });
// //
// //       if (isOpen && startTimeMillis != null) {
// //         _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
// //         _startTimer();
// //         _listenToAttendanceCount(sessionId!);
// //       } else {
// //         _stopTimer();
// //         _attendanceCountSubscription?.cancel();
// //         if (!mounted) return;
// //         setState(() {
// //           _presentStudentCount = 0;
// //         });
// //       }
// //     });
// //   }
// //
// //   void _listenToAttendanceCount(String sessionId) {
// //     _attendanceCountSubscription?.cancel();
// //     final currentDate = DateTime.now().toIso8601String().split('T').first;
// //     final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance/$currentDate/$sessionId');
// //     _attendanceCountSubscription = ref.onValue.listen((event) {
// //       if (!mounted) return;
// //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
// //       if (data != null) {
// //         final count = data.values.where((status) => status == 'Present').length;
// //         setState(() {
// //           _presentStudentCount = count;
// //         });
// //       }
// //     });
// //   }
// //
// //   void _startTimer() {
// //     _sessionTimer?.cancel();
// //     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       if (!mounted) {
// //         timer.cancel();
// //         return;
// //       }
// //       setState(() {
// //         if (_sessionStartTime != null) {
// //           _sessionDurationInSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
// //         }
// //       });
// //     });
// //   }
// //
// //   void _stopTimer() {
// //     _sessionTimer?.cancel();
// //     if (!mounted) return;
// //     setState(() {
// //       _sessionDurationInSeconds = 0;
// //       _sessionStartTime = null;
// //     });
// //   }
// //
// //   Future<void> _refreshStatus() async {
// //     await _getLocationAndPermissions();
// //     Fluttertoast.showToast(msg: 'Status refreshed!');
// //   }
// //
// //   Future<void> openSession() async {
// //     if (_currentLocation == null) {
// //       Fluttertoast.showToast(msg: 'Fetching location, please wait...');
// //       await _getLocationAndPermissions();
// //       if (_currentLocation == null) {
// //         return;
// //       }
// //     }
// //
// //     try {
// //       final currentDate = DateTime.now().toIso8601String().split('T').first;
// //       final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
// //       final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
// //
// //       await ref.child('attendance/$currentDate/$sessionId').set({
// //         'initialized': true,
// //         'teacherLat': _currentLocation!.latitude,
// //         'teacherLon': _currentLocation!.longitude,
// //       });
// //
// //       await ref.update({
// //         'portalOpen': true,
// //         'currentSessionId': sessionId,
// //         'sessionStartTime': DateTime.now().millisecondsSinceEpoch,
// //       });
// //
// //       if (!mounted) return;
// //       Fluttertoast.showToast(msg: 'Session $sessionId opened for $currentDate');
// //     } catch (e) {
// //       Fluttertoast.showToast(msg: 'Error: $e');
// //     }
// //   }
// //
// //   Future<void> closeSession() async {
// //     if (_currentSessionId == null) {
// //       Fluttertoast.showToast(msg: 'No session is active.');
// //       return;
// //     }
// //
// //     try {
// //       final currentDate = DateTime.now().toIso8601String().split('T').first;
// //       final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
// //       final attendanceSnap = await ref.child('attendance/$currentDate/$_currentSessionId').get();
// //       final studentSnap = await ref.child('joinedStudents').get();
// //
// //       if (!attendanceSnap.exists || !studentSnap.exists) {
// //         Fluttertoast.showToast(msg: 'Missing attendance or student data.');
// //         return;
// //       }
// //
// //       final Map<String, dynamic> attendanceData = Map.from(attendanceSnap.value as Map);
// //       final Map<String, dynamic> studentData = Map.from(studentSnap.value as Map);
// //
// //       final recorded = attendanceData.keys.toSet();
// //
// //       for (final uid in studentData.keys) {
// //         if (!recorded.contains(uid)) {
// //           await ref.child('attendance/$currentDate/$_currentSessionId/$uid').set('Absent');
// //         }
// //       }
// //
// //       await ref.update({
// //         'portalOpen': false,
// //         'currentSessionId': null,
// //         'sessionStartTime': null,
// //       });
// //
// //       Fluttertoast.showToast(msg: 'Session closed. Absentees marked.');
// //     } catch (e) {
// //       Fluttertoast.showToast(msg: 'Error: $e');
// //     }
// //   }
// //
// //   Future<bool> _onWillPop() async {
// //     if (_isSessionOpen) {
// //       showDialog(
// //         context: context,
// //         builder: (ctx) => AlertDialog(
// //           title: Text(
// //             'Cannot go back',
// //             style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
// //           ),
// //           content: Text(
// //             'Please end the current session before leaving this page.',
// //             style: GoogleFonts.poppins(),
// //           ),
// //           actions: [
// //             ElevatedButton(
// //               onPressed: () => Navigator.of(ctx).pop(false),
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF3C3E52),
// //                 foregroundColor: Colors.white,
// //               ),
// //               child: Text(
// //                 'OK',
// //                 style: GoogleFonts.poppins(),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //       return false; // Prevent back navigation
// //     }
// //     return true; // Allow back navigation
// //   }
// //
// //   String _formatTime(int seconds) {
// //     final minutes = seconds ~/ 60;
// //     final remainingSeconds = seconds % 60;
// //     return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bool isSessionActive = _isSessionOpen && _currentSessionId != null;
// //
// //     return PopScope(
// //       canPop: !isSessionActive,
// //       onPopInvoked: (bool didPop) {
// //         if (didPop) return;
// //         _onWillPop();
// //       },
// //       child: Scaffold(
// //         backgroundColor: const Color(0xFFF1F0E8),
// //         appBar: AppBar(
// //           title: Text(
// //             "Teacher Portal",
// //             style: GoogleFonts.poppins(
// //               fontWeight: FontWeight.bold,
// //               color: Colors.white,
// //             ),
// //           ),
// //           backgroundColor: const Color(0xFF3C3E52),
// //           foregroundColor: Colors.white,
// //           automaticallyImplyLeading: !isSessionActive, // Hide back button if session is active
// //           actions: [
// //             IconButton(
// //               icon: const Icon(Icons.refresh),
// //               onPressed: _refreshStatus,
// //               tooltip: "Refresh Status",
// //             ),
// //           ],
// //         ),
// //         body: SingleChildScrollView(
// //           padding: const EdgeInsets.all(24.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               Align(
// //                 alignment: Alignment.center,
// //                 child: Image.asset(
// //                   'assets/koala.png',
// //                   height: 100,
// //                 ),
// //               ),
// //               const SizedBox(height: 24),
// //               Text(
// //                 "Welcome to your portal, teacher!",
// //                 style: GoogleFonts.poppins(
// //                   fontSize: 22,
// //                   fontWeight: FontWeight.bold,
// //                   color: const Color(0xFF3C3E52),
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 24),
// //               Card(
// //                 elevation: 4,
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(24.0),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         "Class ID: ${widget.classId}",
// //                         style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C3E52)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Text(
// //                         "Teacher ID: ${widget.teacherUid}",
// //                         style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Row(
// //                         children: [
// //                           const Icon(Icons.location_on, color: Color(0xFF6A798C), size: 20),
// //                           const SizedBox(width: 8),
// //                           Expanded(
// //                             child: Text(
// //                               "Current Location: ${_currentLocation?.latitude.toStringAsFixed(4) ?? 'N/A'}, ${_currentLocation?.longitude.toStringAsFixed(4) ?? 'N/A'}",
// //                               style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
// //                               overflow: TextOverflow.ellipsis,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Row(
// //                         children: [
// //                           Icon(isSessionActive ? Icons.check_circle : Icons.cancel, color: isSessionActive ? Colors.green : Colors.red, size: 20),
// //                           const SizedBox(width: 8),
// //                           Text(
// //                             "Session Status: ${isSessionActive ? 'Active' : 'Inactive'}",
// //                             style: GoogleFonts.poppins(
// //                               fontSize: 16,
// //                               fontWeight: FontWeight.bold,
// //                               color: isSessionActive ? Colors.green : Colors.red,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                       if (isSessionActive)
// //                         Padding(
// //                           padding: const EdgeInsets.only(top: 12.0),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Text(
// //                                 "Current Session ID: $_currentSessionId",
// //                                 style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6A798C)),
// //                               ),
// //                               const SizedBox(height: 8),
// //                               Center(
// //                                 child: Text(
// //                                   _formatTime(_sessionDurationInSeconds),
// //                                   style: GoogleFonts.poppins(
// //                                     fontSize: 36,
// //                                     fontWeight: FontWeight.bold,
// //                                     color: const Color(0xFF3C3E52),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 30),
// //               ElevatedButton.icon(
// //                 icon: isSessionActive
// //                     ? const Icon(Icons.refresh, color: Colors.white)
// //                     : const Icon(Icons.play_circle_fill, color: Colors.white),
// //                 label: Text(
// //                   isSessionActive ? 'Refresh Status' : 'Start New Session',
// //                   style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
// //                 ),
// //                 onPressed: isSessionActive ? _refreshStatus : openSession,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: isSessionActive ? const Color(0xFF2E8B57) : const Color(0xFF2E8B57),
// //                   foregroundColor: Colors.white,
// //                   padding: const EdgeInsets.symmetric(vertical: 16),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 16),
// //               ElevatedButton.icon(
// //                 icon: const Icon(Icons.lock, color: Colors.white),
// //                 label: Text(
// //                   'End Current Session',
// //                   style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
// //                 ),
// //                 onPressed: isSessionActive ? closeSession : null,
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: isSessionActive ? Colors.red : const Color(0xFF6A798C),
// //                   foregroundColor: Colors.white,
// //                   padding: const EdgeInsets.symmetric(vertical: 16),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class TeacherPortalScreen extends StatefulWidget {
//   final String teacherUid;
//   final String classId;
//
//   const TeacherPortalScreen({Key? key, required this.teacherUid, required this.classId}) : super(key: key);
//
//   @override
//   State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
// }
//
// class _TeacherPortalScreenState extends State<TeacherPortalScreen> {
//   String _status = "Loading...";
//   Position? _currentLocation;
//   String? _currentSessionId;
//   bool _isSessionOpen = false;
//
//   Timer? _sessionTimer;
//   int _sessionDurationInSeconds = 0;
//   DateTime? _sessionStartTime;
//   StreamSubscription? _sessionStatusSubscription;
//   StreamSubscription? _attendanceCountSubscription;
//   int _presentStudentCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _getLocationAndPermissions();
//     _listenToSessionStatus();
//   }
//
//   @override
//   void dispose() {
//     _sessionTimer?.cancel();
//     _sessionStatusSubscription?.cancel();
//     _attendanceCountSubscription?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _getLocationAndPermissions() async {
//     if (!mounted) return;
//     setState(() {
//       _status = "Checking location permissions...";
//     });
//
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         Fluttertoast.showToast(msg: 'Location services are disabled. Please enable them.');
//         setState(() => _status = "Location services disabled");
//         return;
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           Fluttertoast.showToast(msg: 'Location permissions are permanently denied.');
//           setState(() => _status = "Location permissions denied");
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         Fluttertoast.showToast(msg: 'Location permissions are permanently denied, we cannot request permissions.');
//         setState(() => _status = "Location permissions permanently denied");
//         return;
//       }
//
//       _currentLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       if (!mounted) return;
//       setState(() {
//         _status = "Ready";
//       });
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error getting location: $e');
//       if (!mounted) return;
//       setState(() => _status = "Error getting location");
//     }
//   }
//
//   // In _TeacherPortalScreenState
//   void _listenToSessionStatus() {
//     final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
//     _sessionStatusSubscription = ref.onValue.listen((event) {
//       if (!mounted) return;
//
//       // FIX: Robust type-check for the main class node
//       final dynamic value = event.snapshot.value;
//       final data = value is Map ? Map<String, dynamic>.from(value) : null;
//
//       final isOpen = data?['portalOpen'] as bool? ?? false;
//       final sessionId = data?['currentSessionId'] as String?;
//       // Session start time is retrieved as an int (number)
//       final startTimeMillis = data?['sessionStartTime'] as int?;
//
//       setState(() {
//         _isSessionOpen = isOpen;
//         _currentSessionId = sessionId;
//       });
//
//       if (isOpen && sessionId != null && startTimeMillis != null) {
//         _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//         _startTimer();
//         _listenToAttendanceCount(sessionId);
//       } else {
//         _stopTimer();
//         _attendanceCountSubscription?.cancel();
//         if (!mounted) return;
//         setState(() {
//           _presentStudentCount = 0;
//         });
//       }
//     });
//   }
//   void _listenToAttendanceCount(String sessionId) {
//     _attendanceCountSubscription?.cancel();
//     final currentDate = DateTime.now().toIso8601String().split('T').first;
//     final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance/$currentDate/$sessionId');
//     _attendanceCountSubscription = ref.onValue.listen((event) {
//       if (!mounted) return;
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final count = data.values.where((status) => status == 'Present').length;
//         setState(() {
//           _presentStudentCount = count;
//         });
//       }
//     });
//   }
//
//   void _startTimer() {
//     _sessionTimer?.cancel();
//     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       setState(() {
//         if (_sessionStartTime != null) {
//           _sessionDurationInSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
//           if (_sessionDurationInSeconds >= 300) { // 5 minutes = 300 seconds
//             closeSession();
//           }
//         }
//       });
//     });
//   }
//
//   void _stopTimer() {
//     _sessionTimer?.cancel();
//     if (!mounted) return;
//     setState(() {
//       _sessionDurationInSeconds = 0;
//       _sessionStartTime = null;
//     });
//   }
//
//   Future<void> _refreshStatus() async {
//     await _getLocationAndPermissions();
//     Fluttertoast.showToast(msg: 'Status refreshed!');
//   }
//
//   // In _TeacherPortalScreenState
//   Future<void> openSession() async {
//     if (_currentLocation == null) {
//       Fluttertoast.showToast(msg: 'Fetching location, please wait...');
//       await _getLocationAndPermissions();
//       if (_currentLocation == null) {
//         return;
//       }
//     }
//
//     try {
//       final currentDate = DateTime.now().toIso8601String().split('T').first;
//       final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
//       final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
//
//       await ref.child('attendance/$currentDate/$sessionId').set({
//         'initialized': true,
//         // CRITICAL FIX: Store coordinates as Strings
//         'teacherLat': _currentLocation!.latitude.toString(),
//         'teacherLon': _currentLocation!.longitude.toString(),
//       });
//
//       await ref.update({
//         'portalOpen': true,
//         'currentSessionId': sessionId,
//         'sessionStartTime': DateTime.now().millisecondsSinceEpoch,
//       });
//
//       if (!mounted) return;
//       Fluttertoast.showToast(msg: 'Session $sessionId opened for $currentDate');
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error: $e');
//     }
//   }
//
//   Future<void> closeSession() async {
//     if (_currentSessionId == null) {
//       Fluttertoast.showToast(msg: 'No session is active.');
//       return;
//     }
//
//     try {
//       final currentDate = DateTime.now().toIso8601String().split('T').first;
//       final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
//       final attendanceSnap = await ref.child('attendance/$currentDate/$_currentSessionId').get();
//       final studentSnap = await ref.child('joinedStudents').get();
//
//       if (!attendanceSnap.exists || !studentSnap.exists) {
//         Fluttertoast.showToast(msg: 'Missing attendance or student data.');
//         return;
//       }
//
//       final Map<String, dynamic> attendanceData = Map.from(attendanceSnap.value as Map);
//       final Map<String, dynamic> studentData = Map.from(studentSnap.value as Map);
//
//       final recorded = attendanceData.keys.toSet();
//
//       for (final uid in studentData.keys) {
//         if (!recorded.contains(uid)) {
//           await ref.child('attendance/$currentDate/$_currentSessionId/$uid').set('Absent');
//         }
//       }
//
//       await ref.update({
//         'portalOpen': false,
//         'currentSessionId': null,
//         'sessionStartTime': null,
//       });
//
//       Fluttertoast.showToast(msg: 'Session closed. Absentees marked.');
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error: $e');
//     }
//   }
//
//   Future<bool> _onWillPop() async {
//     if (_isSessionOpen) {
//       showDialog(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: Text(
//             'Cannot go back',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Please end the current session before leaving this page.',
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () => Navigator.of(ctx).pop(false),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF3C3E52),
//                 foregroundColor: Colors.white,
//               ),
//               child: Text(
//                 'OK',
//                 style: GoogleFonts.poppins(),
//               ),
//             ),
//           ],
//         ),
//       );
//       return false; // Prevent back navigation
//     }
//     return true; // Allow back navigation
//   }
//
//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isSessionActive = _isSessionOpen && _currentSessionId != null;
//
//     return PopScope(
//       canPop: !isSessionActive,
//       onPopInvoked: (bool didPop) {
//         if (didPop) return;
//         _onWillPop();
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF1F0E8),
//         appBar: AppBar(
//           title: Text(
//             "Teacher Portal",
//             style: GoogleFonts.poppins(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           backgroundColor: const Color(0xFF3C3E52),
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: !isSessionActive, // Hide back button if session is active
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _refreshStatus,
//               tooltip: "Refresh Status",
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 24),
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Class ID: ${widget.classId}",
//                         style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3C3E52)),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         "Teacher ID: ${widget.teacherUid}",
//                         style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           const Icon(Icons.location_on, color: Color(0xFF6A798C), size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Current Location: ${_currentLocation?.latitude.toStringAsFixed(4) ?? 'N/A'}, ${_currentLocation?.longitude.toStringAsFixed(4) ?? 'N/A'}",
//                               style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF6A798C)),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Icon(isSessionActive ? Icons.check_circle : Icons.cancel, color: isSessionActive ? Colors.green : Colors.red, size: 20),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Session Status: ${isSessionActive ? 'Active' : 'Inactive'}",
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: isSessionActive ? Colors.green : Colors.red,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (isSessionActive)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 12.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Current Session ID: $_currentSessionId",
//                                 style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6A798C)),
//                               ),
//                               const SizedBox(height: 8),
//                               Center(
//                                 child: Text(
//                                   _formatTime(_sessionDurationInSeconds),
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 36,
//                                     fontWeight: FontWeight.bold,
//                                     color: const Color(0xFF3C3E52),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(Icons.people, color: Colors.blue, size: 20),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'Present Students: $_presentStudentCount',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.blue,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton.icon(
//                 icon: isSessionActive
//                     ? const Icon(Icons.refresh, color: Colors.white)
//                     : const Icon(Icons.play_circle_fill, color: Colors.white),
//                 label: Text(
//                   isSessionActive ? 'Refresh Status' : 'Start New Session',
//                   style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 onPressed: isSessionActive ? _refreshStatus : openSession,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isSessionActive ? const Color(0xFF2E8B57) : const Color(0xFF2E8B57),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.lock, color: Colors.white),
//                 label: Text(
//                   'End Current Session',
//                   style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 onPressed: isSessionActive ? closeSession : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isSessionActive ? Colors.red : const Color(0xFF6A798C),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherPortalScreen extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const TeacherPortalScreen({
    Key? key,
    required this.teacherUid,
    required this.classId,
  }) : super(key: key);

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
  int _totalStudentCount = 0;

  @override
  void initState() {
    super.initState();
    _getLocationAndPermissions();
    _listenToSessionStatus();
    _getTotalStudentCount();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionStatusSubscription?.cancel();
    _attendanceCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getTotalStudentCount() async {
    try {
      // 🔥 NEW: Get total students from classMembers
      final membersSnapshot = await FirebaseDatabase.instance
          .ref('classMembers/${widget.classId}')
          .get();

      if (membersSnapshot.exists) {
        int count = 0;
        for (var child in membersSnapshot.children) {
          if (child.key != 'initialized') count++;
        }
        if (mounted) {
          setState(() => _totalStudentCount = count);
        }
      }
    } catch (e) {
      print('Error getting student count: $e');
    }
  }

  Future<void> _getLocationAndPermissions() async {
    if (!mounted) return;
    setState(() => _status = "Checking location permissions...");

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
          msg: 'Location services are disabled. Please enable them.',
          backgroundColor: Colors.red,
        );
        setState(() => _status = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: 'Location permissions are denied.',
            backgroundColor: Colors.red,
          );
          setState(() => _status = "Location permissions denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: 'Location permissions are permanently denied.',
          backgroundColor: Colors.red,
        );
        setState(() => _status = "Location permissions permanently denied");
        return;
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _status = "Ready");

      print('✅ Location obtained: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    } catch (e) {
      print('❌ Error getting location: $e');
      Fluttertoast.showToast(
        msg: 'Error getting location: $e',
        backgroundColor: Colors.red,
      );
      if (!mounted) return;
      setState(() => _status = "Error getting location");
    }
  }

  void _listenToSessionStatus() {
    // 🔥 NEW: Listen to class node directly (no teacher UID nesting!)
    final ref = FirebaseDatabase.instance.ref('classes/${widget.classId}');

    _sessionStatusSubscription = ref.onValue.listen((event) {
      if (!mounted) return;

      final dynamic value = event.snapshot.value;
      final data = value is Map ? Map<String, dynamic>.from(value.cast<Object?, Object?>()) : null;

      final isOpen = data?['portalOpen'] as bool? ?? false;
      final sessionId = data?['currentSessionId'] as String?;
      final startTimeMillis = data?['sessionStartTime'] as int?;

      setState(() {
        _isSessionOpen = isOpen;
        _currentSessionId = sessionId;
      });

      if (isOpen && sessionId != null && startTimeMillis != null) {
        _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        _startTimer();
        _listenToAttendanceCount(sessionId);
      } else {
        _stopTimer();
        _attendanceCountSubscription?.cancel();
        if (!mounted) return;
        setState(() => _presentStudentCount = 0);
      }
    });
  }

  void _listenToAttendanceCount(String sessionId) {
    _attendanceCountSubscription?.cancel();
    final currentDate = DateTime.now().toIso8601String().split('T').first;

    // 🔥 NEW: Listen to attendance node directly
    final ref = FirebaseDatabase.instance.ref(
        'attendance/${widget.classId}/$currentDate/$sessionId'
    );

    _attendanceCountSubscription = ref.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        int count = 0;
        for (var entry in data.entries) {
          if (entry.value is Map) {
            final studentData = entry.value as Map;
            if (studentData['status'] == 'Present') {
              count++;
            }
          }
        }
        setState(() => _presentStudentCount = count);
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

          // Auto-close after 5 minutes (300 seconds)
          if (_sessionDurationInSeconds >= 300) {
            closeSession();
          }
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
    await _getTotalStudentCount();
    Fluttertoast.showToast(
      msg: 'Status refreshed!',
      backgroundColor: Colors.green,
    );
  }

  Future<void> openSession() async {
    if (_currentLocation == null) {
      Fluttertoast.showToast(
        msg: 'Fetching location, please wait...',
        backgroundColor: Colors.orange,
      );
      await _getLocationAndPermissions();
      if (_currentLocation == null) {
        return;
      }
    }

    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final db = FirebaseDatabase.instance.ref();

      // 🔥 NEW OPTIMIZED STRUCTURE
      final updates = <String, dynamic>{
        // Create session record in sessions node
        'sessions/${widget.classId}/$currentDate/$sessionId': {
          'sessionId': sessionId,
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'endTime': null,
          'teacherLat': _currentLocation!.latitude.toString(),
          'teacherLon': _currentLocation!.longitude.toString(),
          'status': 'active',
        },

        // Initialize attendance node for this session
        'attendance/${widget.classId}/$currentDate/$sessionId/initialized': true,

        // Update class with current session info
        'classes/${widget.classId}/portalOpen': true,
        'classes/${widget.classId}/currentSessionId': sessionId,
        'classes/${widget.classId}/sessionStartTime': DateTime.now().millisecondsSinceEpoch,
      };

      await db.update(updates);

      print('✅ Session opened: $sessionId');
      print('📍 Location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      print('💰 Cost: ~0.5KB (vs ~50KB in old structure)');

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Session started! Valid for 5 minutes.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('❌ Error opening session: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> closeSession() async {
    if (_currentSessionId == null) {
      Fluttertoast.showToast(
        msg: 'No session is active.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get all class members
      final membersSnapshot = await db.child('classMembers/${widget.classId}').get();

      if (!membersSnapshot.exists) {
        Fluttertoast.showToast(
          msg: 'No students found in class.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // 🔥 STEP 2: Get current attendance records
      final attendanceSnapshot = await db
          .child('attendance/${widget.classId}/$currentDate/$_currentSessionId')
          .get();

      final attendanceData = attendanceSnapshot.exists
          ? Map<String, dynamic>.from(
          (attendanceSnapshot.value as Map).cast<Object?, Object?>()
      )
          : <String, dynamic>{};

      final recordedStudents = attendanceData.keys.toSet();

      // 🔥 STEP 3: Mark absent students and update stats
      final updates = <String, dynamic>{};
      int absentCount = 0;

      for (var memberSnap in membersSnapshot.children) {
        if (memberSnap.key == 'initialized') continue;

        final studentUid = memberSnap.key!;

        if (!recordedStudents.contains(studentUid)) {
          // Mark as absent
          absentCount++;
          updates['attendance/${widget.classId}/$currentDate/$_currentSessionId/$studentUid'] = {
            'status': 'Absent',
            'markedAt': DateTime.now().millisecondsSinceEpoch,
            'distance': null,
          };

          // Update student's attendance record
          updates['studentAttendance/$studentUid/${widget.classId}/sessions/${currentDate}_$_currentSessionId'] = 'Absent';
        }
      }

      // 🔥 STEP 4: Update session status
      updates['sessions/${widget.classId}/$currentDate/$_currentSessionId/endTime'] =
          DateTime.now().millisecondsSinceEpoch;
      updates['sessions/${widget.classId}/$currentDate/$_currentSessionId/status'] = 'completed';

      // 🔥 STEP 5: Close session in class
      updates['classes/${widget.classId}/portalOpen'] = false;
      updates['classes/${widget.classId}/currentSessionId'] = null;
      updates['classes/${widget.classId}/sessionStartTime'] = null;

      // 🔥 STEP 6: Update class stats
      updates['classStats/${widget.classId}/$currentDate/sessions/$_currentSessionId'] = {
        'presentCount': _presentStudentCount,
        'absentCount': absentCount,
        'totalStudents': _totalStudentCount,
        'percentage': _totalStudentCount > 0
            ? (_presentStudentCount / _totalStudentCount) * 100
            : 0,
      };

      await db.update(updates);

      print('✅ Session closed: $_currentSessionId');
      print('📊 Present: $_presentStudentCount, Absent: $absentCount');

      // 🔥 STEP 7: Update all students' attendance statistics
      await _updateAllStudentStats(currentDate);

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Session closed. $absentCount students marked absent.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('❌ Error closing session: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _updateAllStudentStats(String currentDate) async {
    try {
      final db = FirebaseDatabase.instance.ref();

      // Get all students in class
      final membersSnapshot = await db.child('classMembers/${widget.classId}').get();
      if (!membersSnapshot.exists) return;

      for (var memberSnap in membersSnapshot.children) {
        if (memberSnap.key == 'initialized') continue;

        final studentUid = memberSnap.key!;

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
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      print('✅ Updated stats for all students');
    } catch (e) {
      print('⚠️ Error updating student stats: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSessionOpen) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              Text(
                'Session Active',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('OK', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionActive = _isSessionOpen && _currentSessionId != null;
    final int remainingSeconds = 300 - _sessionDurationInSeconds;
    final double progressPercent = _sessionDurationInSeconds / 300;

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
          automaticallyImplyLeading: !isSessionActive,
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
              // Status Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3C3E52),
                                  ),
                                ),
                                Text(
                                  "$_totalStudentCount students enrolled",
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
                        Icons.location_on,
                        "Location",
                        _currentLocation != null
                            ? "${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}"
                            : "Not available",
                      ),
                      _buildInfoRow(
                        isSessionActive ? Icons.check_circle : Icons.cancel,
                        "Session Status",
                        isSessionActive ? 'Active' : 'Inactive',
                        color: isSessionActive ? Colors.green : Colors.red,
                      ),
                      if (isSessionActive) ...[
                        const Divider(height: 24),
                        Text(
                          "Session ID: $_currentSessionId",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6A798C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Timer Display
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _formatTime(_sessionDurationInSeconds),
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3C3E52),
                                ),
                              ),
                              Text(
                                "Time remaining: ${_formatTime(remainingSeconds > 0 ? remainingSeconds : 0)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progressPercent,
                                backgroundColor: const Color(0xFFE0E0E0),
                                color: progressPercent > 0.8 ? Colors.red : Colors.green,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Attendance Count
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people, color: Colors.blue, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Present: $_presentStudentCount / $_totalStudentCount',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Session Button
              ElevatedButton.icon(
                icon: Icon(
                  isSessionActive ? Icons.refresh : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                label: Text(
                  isSessionActive ? 'Refresh Status' : 'Start New Session',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: isSessionActive ? _refreshStatus : openSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 16),

              // End Session Button
              ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle, color: Colors.white),
                label: Text(
                  'End Current Session',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: isSessionActive ? closeSession : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSessionActive ? Colors.red : const Color(0xFF6A798C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isSessionActive ? 4 : 0,
                ),
              ),

              if (isSessionActive) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Session will auto-close after 5 minutes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? const Color(0xFF6A798C)),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}