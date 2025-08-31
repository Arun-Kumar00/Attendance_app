import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vidhar/create_class_screen.dart';
import 'package:vidhar/join_class.dart';
import 'package:vidhar/splash_screen.dart';
import 'package:vidhar/student_signup.dart';
import 'package:vidhar/Student_dashboard.dart';
import 'package:vidhar/teacher_dashboard.dart';
import 'package:vidhar/view_class_screen.dart';
import 'package:vidhar/view_joined_class_screen.dart';


import 'Login_screen.dart';
import 'Teacher_signup.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role-Based App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/teacherSignup': (context) => TeacherSignupScreen(),
        '/studentSignup': (context) => StudentSignupScreen(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/teacherDashboard': (context) => TeacherDashboard(),
        '/createClass': (context) => CreateClassScreen(),
        '/viewClasses': (context) => ViewClassesScreen(),
        '/viewJoinedClasses': (context) => ViewJoinedClassesScreen(),
        '/joinClass' : (context) => JoinClassScreen(),
      },
    );
  }
}