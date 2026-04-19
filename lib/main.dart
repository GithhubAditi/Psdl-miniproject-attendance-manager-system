import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBbFyntGvpXmtbR30p9ION76We8kfDiKYk",
      authDomain: "student-database-managem-beef4.firebaseapp.com",
      projectId: "student-database-managem-beef4",
      storageBucket: "student-database-managem-beef4.firebasestorage.app",
      messagingSenderId: "244952229731",
      appId: "1:244952229731:web:bf80a30bbc8f980d81d556",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Attendance Manager',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}