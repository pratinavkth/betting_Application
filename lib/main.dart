import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:new_era_assignment/Authentication/Login.dart';
import 'package:new_era_assignment/Authentication/Signup.dart';
import 'package:new_era_assignment/Home/home.dart';
import 'package:new_era_assignment/firebase_options.dart';
import 'package:new_era_assignment/ongoingMatches/ongoinMatch.dart';
import 'package:new_era_assignment/splashScreen.dart';
// import 'firebase';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // App primary color
        scaffoldBackgroundColor: Colors.white, // default background
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Splashscreen(),
        '/signup': (context) => const Signup(),
        '/login': (context) => const Login(),
        '/home':(context) => const Home(),
        '/ongoingMatch':(context)=>const Ongoinmatch(),
      },
    );
  }
}
