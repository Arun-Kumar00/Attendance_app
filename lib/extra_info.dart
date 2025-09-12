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

  const ExtraInfoPage({super.key, required this.teacherUid, required this.classId});

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
      final classRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
      final attendanceSnapshot = await classRef.child('attendance').get();
      final joinedStudentsSnapshot = await classRef.child('joinedStudents').get();
      final usersRef = FirebaseDatabase.instance.ref('users');

      if (!mounted) return;
      if (!joinedStudentsSnapshot.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> students = [];
      final Set<String> attendanceDates = {};

      // Extract attendance dates from the attendance snapshot
      if (attendanceSnapshot.exists) {
        for (var dateSnap in attendanceSnapshot.children) {
          attendanceDates.add(dateSnap.key!);
        }
      }

      // Process each student to get their details and attendance
      for (var studentSnap in joinedStudentsSnapshot.children) {
        final userId = studentSnap.key!;
        final userSnap = await usersRef.child(userId).get();
        if (!userSnap.exists) continue;

        final name = userSnap.child('name').value?.toString() ?? 'Unknown';
        final roll = userSnap.child('rollNumber').value?.toString() ?? 'N/A';

        int totalSessions = 0;
        int present = 0;
        final Map<String, String> dailyAttendance = {};

        for (String date in attendanceDates) {
          final dateSessionSnap = attendanceSnapshot.child(date);
          final sessionData = dateSessionSnap.value as Map<dynamic, dynamic>? ?? {};

          String statusString = "";
          bool foundSession = false;

          sessionData.forEach((key, value) {
            if (key != "initialized" && (value as Map).containsKey(userId)) {
              foundSession = true;
              if (value[userId] == "Present") {
                statusString += "P ";
                present++;
              } else {
                statusString += "A ";
              }
              totalSessions++;
            }
          });

          if (!foundSession) {
            dailyAttendance[date] = "-";
          } else {
            dailyAttendance[date] = statusString.trim();
          }
        }

        double attendancePercentage = totalSessions > 0 ? (present / totalSessions) * 100 : 0;

        students.add({
          "roll": roll,
          "name": name,
          "dailyAttendance": dailyAttendance,
          "totalClasses": totalSessions,
          "classesAttended": present,
          "percentage": attendancePercentage, // Added percentage to the student data
        });
      }

      students.sort((a, b) => a["roll"].compareTo(b["roll"]));

      if (!mounted) return;
      setState(() {
        _students = students;
        _attendanceDates = attendanceDates.toList()..sort();
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching attendance data: $error");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load records. Please try again.";
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.manageExternalStorage.request();
        }
      } else {
        status = await Permission.storage.request();
      }

      if (status != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required to export.")),
        );
        return;
      }

      final excel = Excel.createExcel();
      final Sheet sheet = excel['Attendance Register'];
      sheet.appendRow(["Roll No", "Name", ..._attendanceDates, "Total Classes", "Attended", "Percentage"]);

      for (var student in _students) {
        List<String> row = [student['roll'], student['name']];
        for (String date in _attendanceDates) {
          row.add(student['dailyAttendance'][date] ?? "-");
        }
        row.add(student['totalClasses'].toString());
        row.add(student['classesAttended'].toString());
        row.add("${student['percentage']!.toStringAsFixed(1)}%"); // Add the percentage
        sheet.appendRow(row);
      }

      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/Attendance_${widget.classId}.xlsx';
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Excel file saved to Downloads: Attendance_${widget.classId}.xlsx"),
          action: SnackBarAction(
            label: "Open",
            onPressed: () => OpenFilex.open(path),
          ),
        ),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Export Successful"),
          content: const Text("Do you want to share the Excel file?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(path)], text: "Attendance Sheet");
              },
              child: const Text("Share"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export: $e")),
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
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      )
          : _students.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No student attendance data found for this class.",
            style: TextStyle(fontSize: 18, color: Color(0xFF6A798C)),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10.0,
          horizontalMargin: 16.0,
          headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF3C3E52).withOpacity(0.1)),
          columns: [
            const DataColumn(label: Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
            ..._attendanceDates.map((date) => DataColumn(label: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)))),
            const DataColumn(label: Text("Total Classes", style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text("Attended", style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text("Percentage", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _students.map((student) {
            return DataRow(cells: [
              DataCell(Text(student["roll"])),
              DataCell(Text(student["name"])),
              ..._attendanceDates.map((date) => DataCell(Text(student["dailyAttendance"][date] ?? "-"))),
              DataCell(Text(student["totalClasses"].toString())),
              DataCell(Text(student["classesAttended"].toString())),
              DataCell(Text("${student['percentage']!.toStringAsFixed(1)}%")),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
