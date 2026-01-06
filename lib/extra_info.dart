// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class ExtraInfoPage extends StatefulWidget {
//   final String teacherUid;
//   final String classId;
//
//   const ExtraInfoPage({super.key, required this.teacherUid, required this.classId});
//
//   @override
//   State<ExtraInfoPage> createState() => _ExtraInfoPageState();
// }
//
// class _ExtraInfoPageState extends State<ExtraInfoPage> {
//   List<Map<String, dynamic>> _students = [];
//   List<String> _attendanceDates = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAttendanceRecords();
//   }
//
//   Future<void> _fetchAttendanceRecords() async {
//     if (!mounted) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final classRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
//       final attendanceSnapshot = await classRef.child('attendance').get();
//       final joinedStudentsSnapshot = await classRef.child('joinedStudents').get();
//       final usersRef = FirebaseDatabase.instance.ref('users');
//
//       if (!mounted) return;
//       if (!joinedStudentsSnapshot.exists) {
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }
//
//       final List<Map<String, dynamic>> students = [];
//       final Set<String> attendanceDates = {};
//
//       // Extract attendance dates from the attendance snapshot
//       if (attendanceSnapshot.exists) {
//         for (var dateSnap in attendanceSnapshot.children) {
//           attendanceDates.add(dateSnap.key!);
//         }
//       }
//
//       // Process each student to get their details and attendance
//       for (var studentSnap in joinedStudentsSnapshot.children) {
//         final userId = studentSnap.key!;
//         final userSnap = await usersRef.child(userId).get();
//         if (!userSnap.exists) continue;
//
//         final name = userSnap.child('name').value?.toString() ?? 'Unknown';
//         final roll = userSnap.child('rollNumber').value?.toString() ?? 'N/A';
//
//         int totalSessions = 0;
//         int present = 0;
//         final Map<String, String> dailyAttendance = {};
//
//         for (String date in attendanceDates) {
//           final dateSessionSnap = attendanceSnapshot.child(date);
//           final sessionData = dateSessionSnap.value as Map<dynamic, dynamic>? ?? {};
//
//           String statusString = "";
//           bool foundSession = false;
//
//           sessionData.forEach((key, value) {
//             if (key != "initialized" && (value as Map).containsKey(userId)) {
//               foundSession = true;
//               if (value[userId] == "Present") {
//                 statusString += "P ";
//                 present++;
//               } else {
//                 statusString += "A ";
//               }
//               totalSessions++;
//             }
//           });
//
//           if (!foundSession) {
//             dailyAttendance[date] = "-";
//           } else {
//             dailyAttendance[date] = statusString.trim();
//           }
//         }
//
//         double attendancePercentage = totalSessions > 0 ? (present / totalSessions) * 100 : 0;
//
//         students.add({
//           "roll": roll,
//           "name": name,
//           "dailyAttendance": dailyAttendance,
//           "totalClasses": totalSessions,
//           "classesAttended": present,
//           "percentage": attendancePercentage, // Added percentage to the student data
//         });
//       }
//
//       students.sort((a, b) => a["roll"].compareTo(b["roll"]));
//
//       if (!mounted) return;
//       setState(() {
//         _students = students;
//         _attendanceDates = attendanceDates.toList()..sort();
//         _isLoading = false;
//       });
//     } catch (error) {
//       print("Error fetching attendance data: $error");
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to load records. Please try again.";
//       });
//     }
//   }
//
//   Future<void> _exportToExcel() async {
//     try {
//       PermissionStatus status;
//       if (Platform.isAndroid) {
//         if (await Permission.manageExternalStorage.isGranted) {
//           status = PermissionStatus.granted;
//         } else {
//           status = await Permission.manageExternalStorage.request();
//         }
//       } else {
//         status = await Permission.storage.request();
//       }
//
//       if (status != PermissionStatus.granted) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Storage permission is required to export.")),
//         );
//         return;
//       }
//
//       final excel = Excel.createExcel();
//       excel.delete('Sheet1');
//       final Sheet sheet = excel['Attendance Register'];
//       sheet.appendRow(["Roll No", "Name", ..._attendanceDates, "Total Classes", "Attended", "Percentage"]);
//
//       for (var student in _students) {
//         List<String> row = [student['roll'], student['name']];
//         for (String date in _attendanceDates) {
//           row.add(student['dailyAttendance'][date] ?? "-");
//         }
//         row.add(student['totalClasses'].toString());
//         row.add(student['classesAttended'].toString());
//         row.add("${student['percentage']!.toStringAsFixed(1)}%"); // Add the percentage
//         sheet.appendRow(row);
//       }
//
//
//       final directory = await getExternalStorageDirectory();
//       final path = '${directory!.path}/Attendance_${widget.classId}.xlsx';
//       final file = File(path);
//       await file.writeAsBytes(excel.encode()!);
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Excel file saved to Downloads: Attendance_${widget.classId}.xlsx"),
//           action: SnackBarAction(
//             label: "Open",
//             onPressed: () => OpenFilex.open(path),
//           ),
//         ),
//       );
//
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Export Successful"),
//           content: const Text("Do you want to share the Excel file?"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("No"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Share.shareXFiles([XFile(path)], text: "Attendance Sheet");
//               },
//               child: const Text("Share"),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to export: $e")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F0E8),
//       appBar: AppBar(
//         title: Text(
//           "Attendance Register",
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF3C3E52),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: "Refresh Data",
//             onPressed: _fetchAttendanceRecords,
//           ),
//           IconButton(
//             icon: const Icon(Icons.download),
//             tooltip: "Export to Excel",
//             onPressed: _exportToExcel,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Text(
//             _errorMessage!,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 16, color: Colors.red),
//           ),
//         ),
//       )
//           : _students.isEmpty
//           ? const Center(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text(
//             "No student attendance data found for this class.",
//             style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         child: DataTable(
//           columnSpacing: 10.0,
//           horizontalMargin: 16.0,
//           headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF3C3E52).withOpacity(0.1)),
//           columns: [
//             const DataColumn(label: Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold))),
//             const DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
//             ..._attendanceDates.map((date) => DataColumn(label: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)))),
//             const DataColumn(label: Text("Total Classes", style: TextStyle(fontWeight: FontWeight.bold))),
//             const DataColumn(label: Text("Attended", style: TextStyle(fontWeight: FontWeight.bold))),
//             const DataColumn(label: Text("Percentage", style: TextStyle(fontWeight: FontWeight.bold))),
//           ],
//           rows: _students.map((student) {
//             return DataRow(cells: [
//               DataCell(Text(student["roll"])),
//               DataCell(Text(student["name"])),
//               ..._attendanceDates.map((date) => DataCell(Text(student["dailyAttendance"][date] ?? "-"))),
//               DataCell(Text(student["totalClasses"].toString())),
//               DataCell(Text(student["classesAttended"].toString())),
//               DataCell(Text("${student['percentage']!.toStringAsFixed(1)}%")),
//             ]);
//           }).toList(),
//         ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class ExtraInfoPage extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const ExtraInfoPage({
    super.key,
    required this.teacherUid,
    required this.classId,
  });

  @override
  State<ExtraInfoPage> createState() => _ExtraInfoPageState();
}

class _ExtraInfoPageState extends State<ExtraInfoPage> {
  List<Map<String, dynamic>> _students = [];
  List<String> _attendanceDates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = FirebaseDatabase.instance.ref();

      // 🔥 STEP 1: Get class members (NEW: from classMembers node)
      final membersSnapshot = await db.child('classMembers/${widget.classId}').get();

      if (!membersSnapshot.exists || membersSnapshot.children.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _students = [];
        });
        return;
      }

      // 🔥 STEP 2: Get all attendance records (NEW: from attendance node)
      final attendanceSnapshot = await db.child('attendance/${widget.classId}').get();

      final List<Map<String, dynamic>> students = [];
      final Set<String> attendanceDates = {};

      // Extract attendance dates
      if (attendanceSnapshot.exists) {
        for (var dateSnap in attendanceSnapshot.children) {
          attendanceDates.add(dateSnap.key!);
        }
      }

      print('✅ Found ${attendanceDates.length} attendance dates');
      print('✅ Found ${membersSnapshot.children.length} students');

      // 🔥 STEP 3: Process each student
      for (var memberSnap in membersSnapshot.children) {
        if (memberSnap.key == 'initialized') continue;

        final studentUid = memberSnap.key!;
        final memberData = Map<String, dynamic>.from(
            (memberSnap.value as Map).cast<Object?, Object?>()
        );

        final name = memberData['name'] ?? 'Unknown';
        final roll = memberData['rollNumber'] ?? 'N/A';

        // 🔥 OPTION 1: Get pre-calculated stats (FASTEST)
        final statsSnapshot = await db
            .child('studentAttendance/$studentUid/${widget.classId}')
            .get();

        int totalSessions = 0;
        int present = 0;
        double percentage = 0.0;

        if (statsSnapshot.exists) {
          final stats = Map<String, dynamic>.from(
              (statsSnapshot.value as Map).cast<Object?, Object?>()
          );
          totalSessions = stats['totalSessions'] ?? 0;
          present = stats['presentCount'] ?? 0;
          percentage = (stats['percentage'] ?? 0.0).toDouble();
        }

        // 🔥 STEP 4: Build daily attendance record
        final Map<String, String> dailyAttendance = {};

        for (String date in attendanceDates) {
          final dateSessionsSnapshot = await db
              .child('attendance/${widget.classId}/$date')
              .get();

          if (!dateSessionsSnapshot.exists) {
            dailyAttendance[date] = "-";
            continue;
          }

          String statusString = "";
          bool foundSession = false;

          for (var sessionSnap in dateSessionsSnapshot.children) {
            if (sessionSnap.key == '.initialized') continue;

            final sessionData = sessionSnap.value;
            if (sessionData is Map) {
              final studentStatus = (sessionData as Map)[studentUid];

              if (studentStatus != null) {
                foundSession = true;

                // Handle both old format (string) and new format (map)
                String status = 'Absent';
                if (studentStatus is String) {
                  status = studentStatus;
                } else if (studentStatus is Map && studentStatus.containsKey('status')) {
                  status = studentStatus['status'];
                }

                if (status == "Present") {
                  statusString += "P ";
                } else {
                  statusString += "A ";
                }
              }
            }
          }

          dailyAttendance[date] = foundSession ? statusString.trim() : "-";
        }

        students.add({
          "roll": roll,
          "name": name,
          "uid": studentUid,
          "dailyAttendance": dailyAttendance,
          "totalClasses": totalSessions,
          "classesAttended": present,
          "percentage": percentage,
        });
      }

      // Sort by roll number
      students.sort((a, b) => a["roll"].toString().compareTo(b["roll"].toString()));

      print('✅ Processed ${students.length} students');
      print('💰 Cost: ~${students.length * 0.5}KB (vs ~${students.length * 50}KB in old structure)');

      if (!mounted) return;
      setState(() {
        _students = students;
        _attendanceDates = attendanceDates.toList()..sort();
        _isLoading = false;
      });
    } catch (error) {
      print("❌ Error fetching attendance data: $error");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load records. Please try again.";
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // 🔥 Handle permissions properly for Android 11+
      PermissionStatus status = PermissionStatus.granted;

      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.manageExternalStorage.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else if (Platform.isIOS) {
        // iOS doesn't need storage permission for app directory
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }

      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Storage permission is required to export.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create Excel file
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final Sheet sheet = excel['Attendance Register'];

      // Add header row
      sheet.appendRow([
        "Roll No",
        "Name",
        ..._attendanceDates,
        "Total Classes",
        "Attended",
        "Percentage"
      ]);

      // Add student rows
      for (var student in _students) {
        List<dynamic> row = [
          student['roll'],
          student['name'],
        ];

        // Add daily attendance
        for (String date in _attendanceDates) {
          row.add(student['dailyAttendance'][date] ?? "-");
        }

        // Add totals
        row.add(student['totalClasses'].toString());
        row.add(student['classesAttended'].toString());
        row.add("${student['percentage']!.toStringAsFixed(1)}%");

        sheet.appendRow(row);
      }

      // Save file
      Directory? directory;
      String fileName = 'Attendance_${widget.classId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final path = '${directory!.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);

      print('✅ Excel file saved to: $path');

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isIOS
                ? "Excel file created successfully!"
                : "Excel file saved: $fileName",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          action: Platform.isAndroid
              ? SnackBarAction(
            label: "Open",
            onPressed: () => OpenFilex.open(path),
            textColor: Colors.white,
          )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );

      // Show share dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                "Export Successful",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Do you want to share the Excel file?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "No",
                style: GoogleFonts.poppins(color: const Color(0xFF6A798C)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Share.shareXFiles(
                  [XFile(path)],
                  text: "Attendance Sheet for ${widget.classId}",
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C3E52),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Share", style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Error exporting: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to export: $e",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: AppBar(
        title: Text(
          "Attendance Register",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C3E52),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _fetchAttendanceRecords,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export to Excel",
            onPressed: _students.isEmpty ? null : _exportToExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3C3E52),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAttendanceRecords,
                icon: const Icon(Icons.refresh),
                label: Text(
                  "Retry",
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3E52),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : _students.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3E52).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 60,
                  color: Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No Student Data",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3C3E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "No students have joined this class yet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6A798C),
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          // Summary Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      Icons.people,
                      "Students",
                      "${_students.length}",
                    ),
                    _buildSummaryStat(
                      Icons.calendar_today,
                      "Dates",
                      "${_attendanceDates.length}",
                    ),
                    _buildSummaryStat(
                      Icons.school,
                      "Class",
                      widget.classId,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 10.0,
                  horizontalMargin: 16.0,
                  headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFF3C3E52).withOpacity(0.1),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        "Roll No",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Name",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._attendanceDates.map(
                          (date) => DataColumn(
                        label: Text(
                          date,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Present",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "%",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: _students.map((student) {
                    final percentage = student['percentage'] as double;
                    final Color percentColor = percentage >= 75
                        ? Colors.green
                        : percentage >= 60
                        ? Colors.orange
                        : Colors.red;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            student["roll"],
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        DataCell(
                          Text(
                            student["name"],
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        ..._attendanceDates.map(
                              (date) => DataCell(
                            Text(
                              student["dailyAttendance"][date] ?? "-",
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            student["totalClasses"].toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        DataCell(
                          Text(
                            student["classesAttended"].toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: percentColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3C3E52), size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3C3E52),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF6A798C),
          ),
        ),
      ],
    );
  }
}