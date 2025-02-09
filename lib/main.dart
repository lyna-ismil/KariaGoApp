import 'package:flutter/material.dart';
import 'presentation/views/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KariaGo',
      theme: ThemeData(
        primaryColor: Color(0xFF0055CC), // Same theme as before
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          displayLarge: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold), // Updated from headline1
          bodyLarge: TextStyle(color: Colors.black54, fontSize: 18),
        ),
      ),
      home: SplashScreen(), // Start with Splash Screen
    );
  }
}
