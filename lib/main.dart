import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:work_schedule_app/screens/category_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Work Schedule App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CategoryScreen(),
    );
  }
}
