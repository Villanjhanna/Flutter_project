import 'package:flutter/material.dart';
import 'package:flutter_taplocal/joblist.dart';
import 'package:flutter_taplocal/login.dart';
import 'package:flutter_taplocal/resume_generator.dart';
import 'package:flutter_taplocal/training_list.dart';
import 'package:flutter_taplocal/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late bool isLoggedIn;

  final List<Widget> _screens = [
    JobListScreen(), // New screen for job list
    TrainingsScreen(), // Training list page for admin
    ResumeScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _getLoginStatus();
  }

  // Fetch login status
  void _getLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/taplocal.png', height: 30), // Your logo here
            SizedBox(width: 10),
            Text('TapLocal'),
          ],
        ),
      ),
      body: isLoggedIn
          ? _screens[_selectedIndex] // Show the correct screen
          : LoginPage(),
      bottomNavigationBar: isLoggedIn
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.blue, // Explicit background color
              selectedItemColor: Colors.black, // Color for selected item
              unselectedItemColor: Colors.grey, // Color for unselected items
              elevation:
                  8, // Optional: Adds a shadow effect to the BottomNavigationBar
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.school), label: 'Trainings'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.description), label: 'Resume'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : Container(), // Hide bottom nav if not logged in
    );
  }
}