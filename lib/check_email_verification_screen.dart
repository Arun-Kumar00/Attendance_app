// check_email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CheckEmailVerificationScreen extends StatefulWidget {
  final User user;
  final String? role;
  const CheckEmailVerificationScreen({required this.user, this.role, Key? key}) : super(key: key);

  @override
  _CheckEmailVerificationScreenState createState() => _CheckEmailVerificationScreenState();
}

class _CheckEmailVerificationScreenState extends State<CheckEmailVerificationScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _resendInProgress = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    // Start a periodic timer to lightly poll (optional)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _reloadAndCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reloadAndCheck() async {
    try {
      await widget.user.reload();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh != null && fresh.emailVerified) {
        // update DB flag
        final uid = fresh.uid;
        await FirebaseDatabase.instance.ref("users/$uid").update({'emailVerified': true});
        // navigate to proper dashboard
        if (!mounted) return;
        if ((widget.role ?? 'student') == 'teacher') {
          Navigator.pushReplacementNamed(context, '/teacherDashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/studentDashboard');
        }
      }
    } catch (e) {
      // ignore reload errors
    }
  }

  Future<void> _manualCheck() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    await _reloadAndCheck();
    setState(() => _isChecking = false);
  }

  Future<void> _resendLink() async {
    if (_resendInProgress) return;
    setState(() {
      _resendInProgress = true;
      _secondsLeft = 30;
    });

    try {
      await widget.user.sendEmailVerification();
      Fluttertoast.showToast(msg: "Verification email resent. Check your inbox.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to resend verification email.");
    } finally {
      setState(() => _resendInProgress = false);
      // simple cooldown for the resend button
      Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() { _secondsLeft--; });
        if (_secondsLeft <= 0) t.cancel();
      });
    }
  }

  Future<void> _signOut() async {
    // On sign out we mark emailVerified false and set lastLogout timestamp
    final uid = widget.user.uid;
    await FirebaseDatabase.instance.ref("users/$uid").update({
      'emailVerified': false,
      'lastLogout': DateTime.now().millisecondsSinceEpoch,
    });
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(title: Text("Verify your email", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: const Color(0xFF3C3E52)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text("Verify your email", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("A verification link was sent to:", style: GoogleFonts.poppins()),
                const SizedBox(height: 6),
                Text(email, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                Text(
                  "Open your email and click the verification link. After that, press 'I've verified'.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                    onPressed: _isChecking ? null : _manualCheck,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C3E52)),
                    child: Text(_isChecking ? "Checking..." : "I've verified", style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_resendInProgress || _secondsLeft>0) ? null : _resendLink,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A798C)),
                    child: Text(_secondsLeft>0 ? "Resend (${_secondsLeft}s)" : "Resend link", style: GoogleFonts.poppins()),
                  ),
                ]),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _signOut,
                  child: Text("Cancel & Logout", style: GoogleFonts.poppins(color: const Color(0xFF6A798C))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
