// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class TeacherDashboard extends StatefulWidget {
//   const TeacherDashboard({super.key});
//
//   @override
//   _TeacherDashboardState createState() => _TeacherDashboardState();
// }
//
// class _TeacherDashboardState extends State<TeacherDashboard> {
//   String teacherUid = "";
//   String teacherName = "";
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchTeacherDetails();
//   }
//
//   Future<void> _fetchTeacherDetails() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final snapshot = await FirebaseDatabase.instance.ref().child('users').child(user.uid).get();
//
//         if (snapshot.exists) {
//           if (!mounted) return;
//           setState(() {
//             teacherUid = snapshot.child('uid').value.toString();
//             teacherName = snapshot.child('name').value.toString();
//           });
//         }
//       }
//     } catch (error) {
//       print("Error fetching teacher details: $error");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('role');
//
//     await FirebaseAuth.instance.signOut();
//
//     if (mounted) {
//       Navigator.of(context).pushNamedAndRemoveUntil(
//         '/login',
//             (Route<dynamic> route) => false,
//       );
//     }
//   }
//
//   void _showLogoutConfirmation() {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(
//           "Confirm Logout",
//           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//         ),
//         content: Text(
//           "Are you sure you want to log out?",
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
//               _logout();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF3C3E52),
//               foregroundColor: Colors.white,
//             ),
//             child: Text(
//               "Logout",
//               style: GoogleFonts.poppins(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _copyToClipboard() {
//     Clipboard.setData(ClipboardData(text: teacherUid));
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Teacher UID copied to clipboard!")),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'Teacher Dashboard',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: _showLogoutConfirmation,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 20.0),
//                 child: Image.asset(
//                   'assets/Screenshot_2025-08-31_at_15.47.46-removebg-preview.png',
//                   height: 100,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//             Text(
//               "Welcome, $teacherName!",
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF3C3E52),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             GestureDetector(
//               onTap: _copyToClipboard,
//               child: Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 color: Colors.white,
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     children: [
//                       Text(
//                         "Your UID:",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF6A798C),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Tooltip(
//                         message: "Tap to copy",
//                         child: Text(
//                           teacherUid,
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.poppins(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: const Color(0xFF3C3E52),
//                             letterSpacing: 1.2,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Icon(Icons.content_copy, size: 20, color: Color(0xFF3C3E52)),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/createClass');
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF3C3E52),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 elevation: 5,
//               ),
//               child: Text(
//                 'Create Class',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/viewClasses');
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6A798C),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 elevation: 5,
//               ),
//               child: Text(
//                 'View Existing Classes',
//                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
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
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'teacher_profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherUid = "";
  String teacherName = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance.ref().child('users').child(user.uid).get();

        if (snapshot.exists) {
          if (!mounted) return;
          setState(() {
            teacherUid = snapshot.child('uid').value.toString();
            teacherName = snapshot.child('name').value.toString();
          });
        }
      }
    } catch (error) {
      print("Error fetching teacher details: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showLogoutConfirmation() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to log out?",
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
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3E52),
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: teacherUid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Teacher UID copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'Teacher Dashboard',
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
              Navigator.pushNamed(context, '/teacherProfile');
            },
            tooltip: 'My Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Image.asset(
                  'assets/Screenshot_2025-08-31_at_15.47.46-removebg-preview.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Text(
              "Welcome, $teacherName!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3C3E52),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _copyToClipboard,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "Your UID:",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6A798C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Tooltip(
                        message: "Tap to copy",
                        child: Text(
                          teacherUid,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3C3E52),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.content_copy, size: 20, color: Color(0xFF3C3E52)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/createClass');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C3E52),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: Text(
                'Create Class',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/viewClasses');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A798C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: Text(
                'View Existing Classes',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
