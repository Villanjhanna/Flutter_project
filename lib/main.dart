import 'package:flutter/material.dart';
import 'package:flutter_taplocal/homepage.dart';
import 'package:flutter_taplocal/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Hiring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Show a loading spinner
          } else if (snapshot.hasData && snapshot.data!) {
            return HomePage(); // User is logged in
          } else {
            return LoginPage(); // User is not logged in
          }
        },
      ),
    );
  }

  // Check the login status from shared preferences
  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}


