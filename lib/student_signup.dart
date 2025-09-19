// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class StudentSignupScreen extends StatefulWidget {
//   @override
//   _StudentSignupScreenState createState() => _StudentSignupScreenState();
// }
//
// class _StudentSignupScreenState extends State<StudentSignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _rollNumberController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   String _selectedProgram = 'BTech';
//   String _selectedYear = '1st';
//   String _selectedDepartment = 'CSE1';
//   bool _isLoading = false;
//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//
//   final List<String> _programs = ['BTech', 'MTech'];
//   final List<String> _years = ['1st', '2nd ', '3rd ', '4th'];
//   final List<String> _departments = ['CSE1','CSE2','CE', 'ECE', 'EE', 'ME', 'AE', 'AIDS','M.Tech(CSE&CSA)'];
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _rollNumberController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _signUp() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     final email = _emailController.text.trim();
//     if (!email.endsWith('@nitdelhi.ac.in')) {
//       _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed for student registration.");
//       return;
//     }
//
//     if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
//       _showErrorDialog("Passwords do not match!");
//       return;
//     }
//
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: _passwordController.text.trim(),
//       );
//
//       final userId = userCredential.user!.uid;
//       await FirebaseDatabase.instance.ref().child('users').child(userId).set({
//         'name': _nameController.text.trim(),
//         'email': email,
//         'role': 'student',
//         'rollNumber': _rollNumberController.text.trim(),
//         'program': _selectedProgram,
//         'year': _selectedYear,
//         'department': _selectedDepartment,
//         'uid': userId,
//       });
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('role', 'student');
//
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(context, '/login');
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
//       if (e.code == 'weak-password') {
//         errorMessage = 'The password provided is too weak.';
//       } else if (e.code == 'email-already-in-use') {
//         errorMessage = 'An account already exists for that email.';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'The email address is not valid.';
//       } else {
//         errorMessage = 'Sign-up failed. Please try again.';
//       }
//       _showErrorDialog(errorMessage);
//     } catch (error) {
//       print("Sign-Up failed: $error");
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
//         title: Text("Sign-Up Error", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
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
//           'Student Sign Up',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 30),
//                   Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
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
//                               controller: _nameController,
//                               decoration: InputDecoration(
//                                 labelText: 'Full Name',
//                                 prefixIcon: const Icon(Icons.person, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your name';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _rollNumberController,
//                               decoration: InputDecoration(
//                                 labelText: 'Roll Number',
//                                 prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your Roll Number';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: DropdownButtonFormField<String>(
//                                     value: _selectedProgram,
//                                     decoration: InputDecoration(
//                                       labelText: 'Prog',
//                                       prefixIcon: const Icon(Icons.school, color: Color(0xFF3C3E52)),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                     ),
//                                     items: _programs.map((program) => DropdownMenuItem(value: program, child: Text(program))).toList(),
//                                     onChanged: (value) => setState(() => _selectedProgram = value!),
//                                     validator: (value) {
//                                       if (value == null) return 'Select program';
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: DropdownButtonFormField<String>(
//                                     value: _selectedYear,
//                                     decoration: InputDecoration(
//                                       labelText: 'Year',
//                                       prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3C3E52)),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                     ),
//                                     items: _years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
//                                     onChanged: (value) => setState(() => _selectedYear = value!),
//                                     validator: (value) {
//                                       if (value == null) return 'Select year';
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 20),
//                             DropdownButtonFormField<String>(
//                               value: _selectedDepartment,
//                               decoration: InputDecoration(
//                                 labelText: 'Department',
//                                 prefixIcon: const Icon(Icons.business, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               items: _departments.map((dep) => DropdownMenuItem(value: dep, child: Text(dep))).toList(),
//                               onChanged: (value) => setState(() => _selectedDepartment = value!),
//                               validator: (value) {
//                                 if (value == null) return 'Select department';
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _emailController,
//                               decoration: InputDecoration(
//                                 labelText: 'Email',
//                                 hintText: 'e.g., yourname@nitdelhi.ac.in',
//                                 prefixIcon: const Icon(Icons.email, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               keyboardType: TextInputType.emailAddress,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your email';
//                                 }
//                                 if (!value.contains('@')) {
//                                   return 'Please enter a valid email address';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _passwordController,
//                               decoration: InputDecoration(
//                                 labelText: 'Password',
//                                 hintText: 'Enter a strong password',
//                                 prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                                     color: const Color(0xFF3C3E52),
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _isPasswordVisible = !_isPasswordVisible;
//                                     });
//                                   },
//                                 ),
//                               ),
//                               obscureText: !_isPasswordVisible,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your password';
//                                 }
//                                 if (value.length < 6) {
//                                   return 'Password must be at least 6 characters long';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _confirmPasswordController,
//                               decoration: InputDecoration(
//                                 labelText: 'Confirm Password',
//                                 hintText: 'Re-enter your password',
//                                 prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                                     color: const Color(0xFF3C3E52),
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
//                                     });
//                                   },
//                                 ),
//                               ),
//                               obscureText: !_isConfirmPasswordVisible,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please confirm your password';
//                                 }
//                                 if (value != _passwordController.text) {
//                                   return 'Passwords do not match';
//                                 }
//                                 return null;
//                               },
//                             ),
//
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _signUp,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF3C3E52),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 24,horizontal: 60),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       elevation: 5,
//                     ),
//                     child: AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 300),
//                       transitionBuilder: (Widget child, Animation<double> animation) {
//                         return FadeTransition(opacity: animation, child: child);
//                       },
//                       child: _isLoading
//                           ? const SizedBox(
//                         key: ValueKey('loading'),
//                         width: 48,
//                         height: 48,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                           : Text(
//                         'Sign Up',
//                         key: const ValueKey('signup'),
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_isLoading)
//             const Opacity(
//               opacity: 0.8,
//               child: ModalBarrier(dismissible: false, color: Colors.black),
//             ),
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),
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
import 'package:device_info_plus/device_info_plus.dart';

import 'otp_verification_screen.dart';

class StudentSignupScreen extends StatefulWidget {
  @override
  _StudentSignupScreenState createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedProgram = 'BTech';
  String _selectedYear = '1st';
  String _selectedDepartment = 'CSE1';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<String> _programs = ['BTech', 'MTech'];
  final List<String> _years = ['1st', '2nd ', '3rd ', '4th'];
  final List<String> _departments = ['CSE1','CSE2','CE', 'ECE', 'EE', 'ME', 'AE', 'AIDS','M.Tech(CSE&CSA)'];

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    if (!email.endsWith('@nitdelhi.ac.in')) {
      _showErrorDialog("Only @nitdelhi.ac.in email addresses are allowed for student registration.");
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showErrorDialog("Passwords do not match!");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      // Get device ID
      final deviceId = await _getDeviceId();

      await FirebaseDatabase.instance.ref().child('users').child(userId).set({
        'name': _nameController.text.trim(),
        'email': email,
        'role': 'student',
        'rollNumber': _rollNumberController.text.trim(),
        'program': _selectedProgram,
        'year': _selectedYear,
        'department': _selectedDepartment,
        'uid': userId,
        'deviceId': deviceId, // Store device ID on signup
      });

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            user: userCredential.user!,
            role: 'student',
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Sign-up failed. Please try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      print("Sign-Up failed: $error");
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
        title: Text("Sign-Up Error", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          'Student Sign Up',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
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
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _rollNumberController,
                              decoration: InputDecoration(
                                labelText: 'Roll Number',
                                prefixIcon: const Icon(Icons.confirmation_number, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Roll Number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedProgram,
                                    decoration: InputDecoration(
                                      labelText: 'Prog',
                                      prefixIcon: const Icon(Icons.school, color: Color(0xFF3C3E52)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: _programs.map((program) => DropdownMenuItem(value: program, child: Text(program))).toList(),
                                    onChanged: (value) => setState(() => _selectedProgram = value!),
                                    validator: (value) {
                                      if (value == null) return 'Select program';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedYear,
                                    decoration: InputDecoration(
                                      labelText: 'Year',
                                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3C3E52)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: _years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                                    onChanged: (value) => setState(() => _selectedYear = value!),
                                    validator: (value) {
                                      if (value == null) return 'Select year';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                prefixIcon: const Icon(Icons.business, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _departments.map((dep) => DropdownMenuItem(value: dep, child: Text(dep))).toList(),
                              onChanged: (value) => setState(() => _selectedDepartment = value!),
                              validator: (value) {
                                if (value == null) return 'Select department';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
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
                                hintText: 'Enter a strong password',
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
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF3C3E52)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF3C3E52),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C3E52),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24,horizontal: 60),
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
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Sign Up',
                        key: const ValueKey('signup'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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