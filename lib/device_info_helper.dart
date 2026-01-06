import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Device Verification Helper
/// Adds an extra layer of security by verifying device ID
class DeviceVerificationHelper {

  /// Get current device ID
  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID - unique per device
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown'; // iOS identifier
      }

      return 'unknown';
    } catch (e) {
      print("Error getting device ID: $e");
      return 'unknown';
    }
  }

  /// Verify device during login (call this in login flow)
  /// Returns: true if device is verified, false if blocked
  static Future<bool> verifyDeviceOnLogin({
    required String uid,
    required String role,
    required bool hasActiveSession,
    required BuildContext context,
  }) async {
    // Only check students
    if (role != 'student') return true;

    try {
      // Get current device ID
      final currentDeviceId = await getDeviceId();

      // Get registered device ID from database
      final userRef = FirebaseDatabase.instance.ref("users/$uid");
      final snap = await userRef.get();

      if (!snap.exists) return true;

      final userData = Map<String, dynamic>.from(snap.value as Map);
      final registeredDeviceId = userData['deviceId'] ?? '';

      // If no device registered yet, register current device
      if (registeredDeviceId.isEmpty || registeredDeviceId == 'unknown') {
        await userRef.child('deviceId').set(currentDeviceId);
        await userRef.child('deviceRegisteredAt').set(DateTime.now().millisecondsSinceEpoch);
        return true;
      }

      // If there's an active session, strictly enforce device match
      if (hasActiveSession) {
        if (currentDeviceId != registeredDeviceId) {
          // Device mismatch during active session - BLOCK
          if (context.mounted) {
            _showDeviceMismatchDialog(context, isActiveSession: true);
          }
          return false;
        }
      } else {
        // No active session - allow but log if different device
        if (currentDeviceId != registeredDeviceId) {
          // Log security event
          await _logSecurityEvent(uid, {
            'type': 'device_change',
            'previousDevice': registeredDeviceId,
            'newDevice': currentDeviceId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // Show warning but allow login
          if (context.mounted) {
            _showDeviceChangeWarning(context, uid, currentDeviceId);
          }
        }
      }

      return true;
    } catch (e) {
      print("Error verifying device: $e");
      return true; // Fail open on error
    }
  }

  /// Update registered device (useful for device changes)
  static Future<bool> updateRegisteredDevice(
      BuildContext context,
      String uid,
      String newDeviceId,
      ) async {
    try {
      final userRef = FirebaseDatabase.instance.ref("users/$uid");

      await userRef.update({
        'deviceId': newDeviceId,
        'deviceRegisteredAt': DateTime.now().millisecondsSinceEpoch,
        'deviceChangeReason': 'user_initiated',
      });

      Fluttertoast.showToast(msg: "Device registered successfully!");
      return true;
    } catch (e) {
      print("Error updating device: $e");
      Fluttertoast.showToast(msg: "Failed to register device");
      return false;
    }
  }

  /// Show device mismatch dialog
  static void _showDeviceMismatchDialog(BuildContext context, {required bool isActiveSession}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Device Verification Failed",
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
              isActiveSession
                  ? "You cannot login from a different device during an active attendance session."
                  : "This device doesn't match your registered device.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Security Notice:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActiveSession
                        ? "• Wait for the attendance session to end\n• Or contact your teacher for assistance"
                        : "• If this is your new device, contact support\n• This prevents unauthorized access",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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

  /// Show device change warning
  static void _showDeviceChangeWarning(BuildContext context, String uid, String newDeviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Text(
              "New Device Detected",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're logging in from a different device.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "Would you like to register this as your primary device?",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Note: During active attendance sessions, you can only login from your registered device.",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Later",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await updateRegisteredDevice(context, uid, newDeviceId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C3E52),
            ),
            child: Text(
              "Register Device",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Log security events
  static Future<void> _logSecurityEvent(String uid, Map<String, dynamic> event) async {
    try {
      final logRef = FirebaseDatabase.instance.ref("securityLogs/$uid");
      await logRef.push().set(event);
    } catch (e) {
      print("Error logging security event: $e");
    }
  }

  /// Get device info for display
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice.toString(),
        };
      }

      return {'deviceId': 'unknown'};
    } catch (e) {
      print("Error getting device info: $e");
      return {'deviceId': 'unknown'};
    }
  }
}

