// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class StudentDashboard extends StatelessWidget {
//   const StudentDashboard({super.key});
//
//   Future<void> _logout(BuildContext context) async {
//     // Show a confirmation dialog
//     final shouldLogout = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Confirm Logout',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Are you sure you want to log out?',
//             style: GoogleFonts.poppins(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text(
//                 'Cancel',
//                 style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 'Logout',
//                 style: GoogleFonts.poppins(),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (shouldLogout == true) {
//       // Clear user role from SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('role');
//
//       // Sign out from Firebase
//       await FirebaseAuth.instance.signOut();
//
//       // Navigate back to the login screen and remove all previous routes
//       if (context.mounted) {
//         Navigator.of(context).pushNamedAndRemoveUntil(
//           '/login',
//               (Route<dynamic> route) => false,
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'Student Dashboard',
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
//             onPressed: () => _logout(context),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Koala icon at the top
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 20.0),
//                 child: Image.asset(
//                   'assets/Screenshot_2025-08-31_at_15.47.46-removebg-preview.png',
//                   height: 120,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//             // Welcome message
//             Text(
//               "Welcome, Student!",
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF3C3E52),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             Card(
//               elevation: 5,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
//                 child: Column(
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/joinClass');
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF3C3E52),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         elevation: 5,
//                       ),
//                       child: Text(
//                         'Join a Class',
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/viewJoinedClasses');
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF6A798C),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         elevation: 5,
//                       ),
//                       child: Text(
//                         'View Joined Classes',
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
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
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    // Show a confirmation dialog
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
      // Clear user role from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('role');

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate back to the login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (Route<dynamic> route) => false,
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
      body: SingleChildScrollView(
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
    );
  }
}