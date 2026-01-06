//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// import 'check_email_verification_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _isPasswordVisible = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final email = _emailController.text.trim();
//     final password = _passwordController.text.trim();
//
//     if (!email.endsWith('@nitdelhi.ac.in')) {
//       _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed.");
//       return;
//     }
//
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     try {
//       // 1) Sign in with Firebase Auth
//       final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       final user = userCred.user!;
//       final uid = user.uid;
//
//       // 2) Load DB user node
//       final userRef = FirebaseDatabase.instance.ref("users/$uid");
//       final snap = await userRef.get();
//
//       if (!snap.exists) {
//         await FirebaseAuth.instance.signOut();
//         _showErrorDialog("User data not found. Please register or contact support.");
//         return;
//       }
//
//       final data = Map<String, dynamic>.from(snap.value as Map);
//
//       // 3) Logout cooldown check (5 minutes)
//       final now = DateTime.now().millisecondsSinceEpoch;
//       final lastLogout = data['lastLogout'] ?? 0;
//       if (now - lastLogout < 300000) {
//         final remainSec = ((300000 - (now - lastLogout)) / 1000).round();
//         await FirebaseAuth.instance.signOut();
//         _showErrorDialog("Please wait $remainSec seconds before logging in again.");
//         return;
//       }
//
//       // 4) Check DB emailVerified flag — we force verification every login if DB says false
//       final dbVerified = data['emailVerified'] ?? false;
//       if (!dbVerified) {
//         // send verification link via Firebase Auth
//         try {
//           await user.sendEmailVerification();
//         } catch (e) {
//           // ignore send errors but show toast
//           Fluttertoast.showToast(msg: "Couldn't send verification email. Try again.");
//         }
//
//         // navigate to check email screen where user can confirm they clicked link
//         if (!mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CheckEmailVerificationScreen(user: user, role: data['role']),
//           ),
//         );
//         return;
//       }
//
//       // 5) All checks passed — save role & navigate
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('role', data['role'] ?? 'student');
//
//       if ((data['role'] ?? 'student') == 'teacher') {
//         Navigator.pushReplacementNamed(context, '/teacherDashboard');
//       } else {
//         Navigator.pushReplacementNamed(context, '/studentDashboard');
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = "Login failed. Please try again.";
//       if (e.code == 'user-not-found') message = 'No user found for that email.';
//       else if (e.code == 'wrong-password') message = 'Wrong password provided for that user.';
//       else if (e.code == 'invalid-email') message = 'The email address is not valid.';
//       else if (e.code == 'user-disabled') message = 'This user account has been disabled.';
//       _showErrorDialog(message);
//     } catch (e) {
//       _showErrorDialog("An unexpected error occurred. Please try again later.");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text("Login Error", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
//         content: Text(message, style: GoogleFonts.poppins()),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: Text("Okay", style: GoogleFonts.poppins(color: const Color(0xFF3C3E52))),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _resetPassword(String email) async {
//     if (email.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your email address.");
//       return;
//     }
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       if (!mounted) return;
//       Fluttertoast.showToast(msg: "Password reset link sent to your email!");
//     } on FirebaseAuthException catch (e) {
//       Fluttertoast.showToast(msg: "Error: ${e.message}");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//         actions: [
//           Image.asset('assets/Nit.png', fit: BoxFit.contain, height: 40),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/Gemini_Generated_Image_sct87jsct87jsct8-removebg-preview.png',
//                     height: 180,
//                     fit: BoxFit.contain,
//                   ),
//                   const SizedBox(height: 12),
//                   Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                     color: Colors.white,
//                     child: Padding(
//                       padding: const EdgeInsets.all(24.0),
//                       child: Form(
//                         key: _formKey,
//                         autovalidateMode: AutovalidateMode.onUserInteraction,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             TextFormField(
//                               controller: _emailController,
//                               decoration: InputDecoration(
//                                 labelText: 'Email',
//                                 hintText: 'e.g., yourname@nitdelhi.ac.in',
//                                 prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               keyboardType: TextInputType.emailAddress,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) return 'Please enter your email';
//                                 if (!value.contains('@')) return 'Please enter a valid email address';
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _passwordController,
//                               decoration: InputDecoration(
//                                 labelText: 'Password',
//                                 hintText: 'Enter your password',
//                                 prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF3C3E52)),
//                                   onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
//                                 ),
//                               ),
//                               obscureText: !_isPasswordVisible,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) return 'Please enter your password';
//                                 if (value.length < 6) return 'Password must be at least 6 characters long';
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 10),
//                             Align(
//                               alignment: Alignment.centerRight,
//                               child: TextButton(
//                                 onPressed: () => _resetPassword(_emailController.text.trim()),
//                                 child: Text('Forgot Password?', style: GoogleFonts.poppins(color: const Color(0xFF6A798C))),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             ElevatedButton(
//                               onPressed: _isLoading ? null : _login,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF3C3E52),
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(vertical: 18),
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                                 elevation: 5,
//                               ),
//                               child: AnimatedSwitcher(
//                                 duration: const Duration(milliseconds: 300),
//                                 child: _isLoading
//                                     ? const SizedBox(key: ValueKey('loading'), width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
//                                     : Text('Login', key: const ValueKey('login'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             TextButton(
//                               onPressed: () {
//                                 if (!mounted) return;
//                                 showDialog(
//                                   context: context,
//                                   builder: (BuildContext context) {
//                                     return AlertDialog(
//                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//                                       title: Text("Who are you?", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
//                                       content: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           ElevatedButton.icon(
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                               Navigator.pushNamed(context, '/teacherSignup');
//                                             },
//                                             icon: const Icon(Icons.school, color: Colors.white),
//                                             label: Text("I am a Teacher", style: GoogleFonts.poppins()),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: const Color(0xFF3C3E52),
//                                               foregroundColor: Colors.white,
//                                               minimumSize: const Size(double.infinity, 45),
//                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                             ),
//                                           ),
//                                           const SizedBox(height: 15),
//                                           ElevatedButton.icon(
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                               Navigator.pushNamed(context, '/studentSignup');
//                                             },
//                                             icon: const Icon(Icons.person, color: Colors.white),
//                                             label: Text("I am a Student", style: GoogleFonts.poppins()),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: const Color(0xFF6A798C),
//                                               foregroundColor: Colors.white,
//                                               minimumSize: const Size(double.infinity, 45),
//                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                               child: Text("New here? Create an Account", style: GoogleFonts.poppins(color: const Color(0xFF6A798C), fontSize: 16)),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//           if (_isLoading)
//             const Opacity(opacity: 0.8, child: ModalBarrier(dismissible: false, color: Colors.black)),
//           if (_isLoading)
//             const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'device_info_helper.dart';

import 'check_email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// NEW: Check if student has any active attendance sessions
  Future<bool> _hasActiveAttendanceSessions(String uid, String role) async {
    if (role != 'student') return false; // Only check for students

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

              // If there's an active session, check if student is in this class
              if (status == 'active') {
                return true; // Found an active session
              }
            }
          }
        }
      }

      return false; // No active sessions found
    } catch (e) {
      print("Error checking active sessions: $e");
      return false; // On error, allow login (fail open)
    }
  }

  /// NEW: Get details of active sessions for error message
  Future<String> _getActiveSessionDetails(String uid) async {
    try {
      final userRef = FirebaseDatabase.instance.ref("users/$uid/joinedClasses");
      final joinedClassesSnap = await userRef.get();

      if (!joinedClassesSnap.exists) return '';

      final joinedClasses = Map<String, dynamic>.from(joinedClassesSnap.value as Map);
      List<String> activeClasses = [];

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
                if (classSnap.exists) {
                  final classData = Map<String, dynamic>.from(classSnap.value as Map);
                  final subjectName = classData['subjectName'] ?? classId;
                  activeClasses.add(subjectName);
                }
              }
            }
          }
        }
      }

      if (activeClasses.isEmpty) return '';
      return activeClasses.join(', ');
    } catch (e) {
      return '';
    }
  }
  Future<void> _login() async {
    //_login ... existing code ...
      if (!_formKey.currentState!.validate()) return;

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (!email.endsWith('@nitdelhi.ac.in')) {
        _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed.");
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);

    try {
      // 1) Sign in with Firebase Auth
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user!;
      final uid = user.uid;

      // 2) Load DB user node
      final userRef = FirebaseDatabase.instance.ref("users/$uid");
      final snap = await userRef.get();

      if (!snap.exists) {
        await FirebaseAuth.instance.signOut();
        _showErrorDialog("User data not found. Please register or contact support.");
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);
      final role = data['role'] ?? 'student';

      // 3) Logout cooldown check (5 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastLogout = data['lastLogout'] ?? 0;
      if (now - lastLogout < 300000) {
        final remainSec = ((300000 - (now - lastLogout)) / 1000).round();
        await FirebaseAuth.instance.signOut();
        _showErrorDialog("Please wait $remainSec seconds before logging in again.");
        return;
      }

      // 4) Check for active attendance sessions (STUDENTS ONLY)
      bool hasActiveSessions = false;
      if (role == 'student') {
        hasActiveSessions = await _hasActiveAttendanceSessions(uid, role);
        if (hasActiveSessions) {
          final activeClasses = await _getActiveSessionDetails(uid);
          await FirebaseAuth.instance.signOut();

          String message = "Cannot login while attendance session is active.";
          if (activeClasses.isNotEmpty) {
            message += "\n\nActive sessions in: $activeClasses";
          }
          message += "\n\nPlease wait for the session to end or contact your teacher.";

          _showErrorDialog(message);
          return;
        }
      }

      // 5) NEW: Device verification (STUDENTS ONLY)
      // ↓↓↓ ADD THIS ENTIRE SECTION ↓↓↓
      if (role == 'student') {
        final deviceVerified = await DeviceVerificationHelper.verifyDeviceOnLogin(
          uid: uid,
          role: role,
          hasActiveSession: hasActiveSessions,
          context: context,
        );

        if (!deviceVerified) {
          await FirebaseAuth.instance.signOut();
          return; // Device verification failed, block login
        }
      }
      // ↑↑↑ END OF NEW SECTION ↑↑↑

      // 6) Check DB emailVerified flag
      final dbVerified = data['emailVerified'] ?? false;
      if (!dbVerified) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          Fluttertoast.showToast(msg: "Couldn't send verification email. Try again.");
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckEmailVerificationScreen(user: user, role: role),
          ),
        );
        return;
      }

      // 7) All checks passed — save role & navigate
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role);

      if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, '/teacherDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/studentDashboard');
      }
    } on FirebaseAuthException catch (e) {
      // ... existing error handling ...
    } catch (e) {
      _showErrorDialog("An unexpected error occurred. Please try again later.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Future<void> _login() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   final email = _emailController.text.trim();
  //   final password = _passwordController.text.trim();
  //
  //   if (!email.endsWith('@nitdelhi.ac.in')) {
  //     _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed.");
  //     return;
  //   }
  //
  //   if (!mounted) return;
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // 1) Sign in with Firebase Auth
  //     final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     final user = userCred.user!;
  //     final uid = user.uid;
  //
  //     // 2) Load DB user node
  //     final userRef = FirebaseDatabase.instance.ref("users/$uid");
  //     final snap = await userRef.get();
  //
  //     if (!snap.exists) {
  //       await FirebaseAuth.instance.signOut();
  //       _showErrorDialog("User data not found. Please register or contact support.");
  //       return;
  //     }
  //
  //     final data = Map<String, dynamic>.from(snap.value as Map);
  //     final role = data['role'] ?? 'student';
  //
  //     // 3) Logout cooldown check (5 minutes)
  //     final now = DateTime.now().millisecondsSinceEpoch;
  //     final lastLogout = data['lastLogout'] ?? 0;
  //     if (now - lastLogout < 300000) {
  //       final remainSec = ((300000 - (now - lastLogout)) / 1000).round();
  //       await FirebaseAuth.instance.signOut();
  //       _showErrorDialog("Please wait $remainSec seconds before logging in again.");
  //       return;
  //     }
  //
  //     // 4) NEW: Check for active attendance sessions (STUDENTS ONLY)
  //     if (role == 'student') {
  //       final hasActiveSessions = await _hasActiveAttendanceSessions(uid, role);
  //       if (hasActiveSessions) {
  //         final activeClasses = await _getActiveSessionDetails(uid);
  //         await FirebaseAuth.instance.signOut();
  //
  //         String message = "Cannot login while attendance session is active.";
  //         if (activeClasses.isNotEmpty) {
  //           message += "\n\nActive sessions in: $activeClasses";
  //         }
  //         message += "\n\nPlease wait for the session to end or contact your teacher.";
  //
  //         _showErrorDialog(message);
  //         return;
  //       }
  //     }
  //
  //     // 5) Check DB emailVerified flag — we force verification every login if DB says false
  //     final dbVerified = data['emailVerified'] ?? false;
  //     if (!dbVerified) {
  //       // send verification link via Firebase Auth
  //       try {
  //         await user.sendEmailVerification();
  //       } catch (e) {
  //         // ignore send errors but show toast
  //         Fluttertoast.showToast(msg: "Couldn't send verification email. Try again.");
  //       }
  //
  //       // navigate to check email screen where user can confirm they clicked link
  //       if (!mounted) return;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => CheckEmailVerificationScreen(user: user, role: role),
  //         ),
  //       );
  //       return;
  //     }
  //
  //     // 6) All checks passed — save role & navigate
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('role', role);
  //
  //     if (role == 'teacher') {
  //       Navigator.pushReplacementNamed(context, '/teacherDashboard');
  //     } else {
  //       Navigator.pushReplacementNamed(context, '/studentDashboard');
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     String message = "Login failed. Please try again.";
  //     if (e.code == 'user-not-found') message = 'No user found for that email.';
  //     else if (e.code == 'wrong-password') message = 'Wrong password provided for that user.';
  //     else if (e.code == 'invalid-email') message = 'The email address is not valid.';
  //     else if (e.code == 'user-disabled') message = 'This user account has been disabled.';
  //     _showErrorDialog(message);
  //   } catch (e) {
  //     _showErrorDialog("An unexpected error occurred. Please try again later.");
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Login Error", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Okay", style: GoogleFonts.poppins(color: const Color(0xFF3C3E52))),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email address.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Fluttertoast.showToast(msg: "Password reset link sent to your email!");
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
        actions: [
          Image.asset('assets/Nit.png', fit: BoxFit.contain, height: 40),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Gemini_Generated_Image_sct87jsct87jsct8-removebg-preview.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'e.g., yourname@nitdelhi.ac.in',
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!value.contains('@')) return 'Please enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF3C3E52)),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your password';
                                if (value.length < 6) return 'Password must be at least 6 characters long';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _resetPassword(_emailController.text.trim()),
                                child: Text('Forgot Password?', style: GoogleFonts.poppins(color: const Color(0xFF6A798C))),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C3E52),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isLoading
                                    ? const SizedBox(key: ValueKey('loading'), width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                    : Text('Login', key: const ValueKey('login'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () {
                                if (!mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      title: Text("Who are you?", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Navigator.pushNamed(context, '/teacherSignup');
                                            },
                                            icon: const Icon(Icons.school, color: Colors.white),
                                            label: Text("I am a Teacher", style: GoogleFonts.poppins()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF3C3E52),
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(double.infinity, 45),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Navigator.pushNamed(context, '/studentSignup');
                                            },
                                            icon: const Icon(Icons.person, color: Colors.white),
                                            label: Text("I am a Student", style: GoogleFonts.poppins()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF6A798C),
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(double.infinity, 45),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text("New here? Create an Account", style: GoogleFonts.poppins(color: const Color(0xFF6A798C), fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Opacity(opacity: 0.8, child: ModalBarrier(dismissible: false, color: Colors.black)),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
        ],
      ),
    );
  }
}