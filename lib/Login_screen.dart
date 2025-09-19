// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';
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
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     final email = _emailController.text.trim();
//     if (!email.endsWith('@nitdelhi.ac.in')) {
//       _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed.");
//       return;
//     }
//
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: _passwordController.text.trim(),
//       );
//
//       final userId = userCredential.user!.uid;
//       final userRef = FirebaseDatabase.instance.ref().child('users').child(userId);
//       final snapshot = await userRef.get();
//
//       if (snapshot.exists) {
//         final userData = snapshot.value as Map;
//         final role = userData['role'];
//
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('role', role);
//
//         if (!mounted) return;
//
//         if (role == 'student') {
//           Navigator.pushReplacementNamed(context, '/studentDashboard');
//         } else if (role == 'teacher') {
//           Navigator.pushReplacementNamed(context, '/teacherDashboard');
//         } else {
//           _showErrorDialog("User role is undefined. Please contact support.");
//         }
//       } else {
//         _showErrorDialog("User data not found. Please register or contact support.");
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
//       if (e.code == 'user-not-found') {
//         errorMessage = 'No user found for that email.';
//       } else if (e.code == 'wrong-password') {
//         errorMessage = 'Wrong password provided for that user.';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'The email address is not valid.';
//       } else if (e.code == 'user-disabled') {
//         errorMessage = 'This user account has been disabled.';
//       } else {
//         errorMessage = 'Login failed. Please check your credentials and try again.';
//       }
//       _showErrorDialog(errorMessage);
//     } catch (error) {
//       print("Login failed: $error");
//       _showErrorDialog("An unexpected error occurred. Please try again later.");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           'Login',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//       ),
//       body: Stack(
//           children: [
//       Center(
//       child: SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//       Center(
//       child: Padding(
//       padding: const EdgeInsets.only(),
//       child: Image.asset(
//         'assets/Gemini_Generated_Image_sct87jsct87jsct8-removebg-preview.png',
//         height: 180,
//         fit: BoxFit.contain,
//       ),
//     ),
//     ),
//     Card(
//     elevation: 5,
//     shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(20),
//     ),
//     color: Colors.white,
//     child: Padding(
//     padding: const EdgeInsets.all(24.0),
//     child: Form(
//     key: _formKey,
//     autovalidateMode: AutovalidateMode.onUserInteraction,
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.stretch,
//     children: [
//     TextFormField(
//     controller: _emailController,
//     decoration: InputDecoration(
//     labelText: 'Email',
//     hintText: 'e.g., yourname@nitdelhi.ac.in',
//     prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
//     border: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     ),
//     ),
//     keyboardType: TextInputType.emailAddress,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter your email';
//     }
//     if (!value.contains('@')) {
//     return 'Please enter a valid email address';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 20),
//     TextFormField(
//     controller: _passwordController,
//     decoration: InputDecoration(
//     labelText: 'Password',
//     hintText: 'Enter your password',
//     prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
//     border: OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     ),
//     suffixIcon: IconButton(
//     icon: Icon(
//     _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//     color: const Color(0xFF3C3E52),
//     ),
//     onPressed: () {
//     setState(() {
//     _isPasswordVisible = !_isPasswordVisible;
//     });
//     },
//     ),
//     ),
//     obscureText: !_isPasswordVisible,
//     validator: (value) {
//     if (value == null || value.isEmpty) {
//     return 'Please enter your password';
//     }
//     if (value.length < 6) {
//     return 'Password must be at least 6 characters long';
//     }
//     return null;
//     },
//     ),
//     const SizedBox(height: 30),
//     ElevatedButton(
//     onPressed: _isLoading ? null : _login,
//     style: ElevatedButton.styleFrom(
//     backgroundColor: const Color(0xFF3C3E52),
//     foregroundColor: Colors.white,
//     padding: const EdgeInsets.symmetric(vertical: 18),
//     shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(15),
//     ),
//     elevation: 5,
//     ),
//     child: AnimatedSwitcher(
//     duration: const Duration(milliseconds: 300),
//     transitionBuilder: (Widget child, Animation<double> animation) {
//     return FadeTransition(opacity: animation, child: child);
//     },
//     child: _isLoading
//     ? const SizedBox(
//     key: ValueKey('loading'),
//     width: 24,
//     height: 24,
//     child: CircularProgressIndicator(
//     strokeWidth: 2,
//     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//     ),
//     )
//         : Text(
//     'Login',
//     key: const ValueKey('login'),
//     style: GoogleFonts.poppins(
//     fontSize: 18,
//     fontWeight: FontWeight.bold,
//     ),
//     ),
//     ),
//     ),
//     const SizedBox(height: 20),
//     TextButton(
//     onPressed: () {
//     if (!mounted) return;
//     showDialog(
//     context: context,
//     builder: (BuildContext context) {
//     return AlertDialog(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//     title: Text("Who are you?", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
//     content: Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//     ElevatedButton.icon(
//     onPressed: () {
//     Navigator.of(context).pop();
//     Navigator.pushNamed(context, '/teacherSignup');
//     },
//     icon: const Icon(Icons.school, color: Colors.white),
//     label: Text("I am a Teacher", style: GoogleFonts.poppins()),
//     style: ElevatedButton.styleFrom(
//     backgroundColor: const Color(0xFF3C3E52),
//     foregroundColor: Colors.white,
//     minimumSize: const Size(double.infinity, 45),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//     ),
//     ),
//     const SizedBox(height: 15),
//     ElevatedButton.icon(
//     onPressed: () {
//     Navigator.of(context).pop();
//     Navigator.pushNamed(context, '/studentSignup');
//     },
//     icon: const Icon(Icons.person, color: Colors.white),
//     label: Text("I am a Student", style: GoogleFonts.poppins()),
//     style: ElevatedButton.styleFrom(
//     backgroundColor: const Color(0xFF6A798C),
//     foregroundColor: Colors.white,
//     minimumSize: const Size(double.infinity, 45),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//     ),
//     ),
//     ],
//     ),
//     );
//     },
//     );
//     },
//     child: Text(
//     "New here? Create an Account",
//     style: GoogleFonts.poppins(color: const Color(0xFF6A798C), fontSize: 16),
//     ),
//     ),
//     ],
//     ),
//     ),
//     ),
//     )],
//     ),
//     ),
//     ),
//     if (_isLoading)
//     const Opacity(
//     opacity: 0.8,
//     child: ModalBarrier(dismissible: false, color: Colors.black),
//     ),
//     if (_isLoading)
//     const Center(
//     child: CircularProgressIndicator(
//     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//     ),
//     ),
//     ],
//     ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'otp_verification_screen.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    if (!email.endsWith('@nitdelhi.ac.in')) {
      _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      // Get device ID
      final deviceId = await _getDeviceId();
      final userRef = FirebaseDatabase.instance.ref().child('users').child(userId);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final storedDeviceId = userData['deviceId'] ?? '';
        final role = userData['role'];

        if (storedDeviceId.isEmpty) {
          // This is a new rollout. Save the device ID for the first time.
          await userRef.update({'deviceId': deviceId});
        } else if (storedDeviceId != deviceId) {
          _showErrorDialog("This account is already registered on another device.");
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        // Send OTP email
        await userCredential.user!.sendEmailVerification();
        if (!mounted) return;

        // Navigate to OTP verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              user: userCredential.user!,
              role: role,
            ),
          ),
        );
      } else {
        _showErrorDialog("User data not found. Please register or contact support.");
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      } else {
        errorMessage = 'Login failed. Please check your credentials and try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      print("Login failed: $error");
      _showErrorDialog("An unexpected error occurred. Please try again later.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? '';
    }
    return '';
  }

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
        title: Text(
          'Login',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
        actions: [
          Image.asset(
            'assets/Nit.png',
            fit: BoxFit.contain,
            height: 40,
          ),
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(),
                      child: Image.asset(
                        'assets/Gemini_Generated_Image_sct87jsct87jsct8-removebg-preview.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF3C3E52),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _resetPassword(_emailController.text.trim());
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3C3E52),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: _isLoading
                                    ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  'Login',
                                  key: const ValueKey('login'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                              child: Text(
                                "New here? Create an Account",
                                style: GoogleFonts.poppins(color: const Color(0xFF6A798C), fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )],
              ),
            ),
          ),
          if (_isLoading)
            const Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}