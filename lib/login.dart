import 'package:flutter/material.dart';
import 'package:flutter_taplocal/homepage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_taplocal/signup.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final Map<String, String> body = {
        'email': emailController.text,
        'password': passwordController.text,
      };

      final response = await http.post(
        Uri.parse('http://s2010681.helioho.st/login.php'),
        headers: headers,
        body: body,
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['message'] != null) {
          print("Login successful: ${data['message']}");

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('user_id', data['user_id']);
          await prefs.setString('role', data['role']);

          // Navigate to HomePage after successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          setState(() {
            _errorMessage = 'Login failed: ${data['error']}';
          });
          print("Login failed: ${data['error']}");
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to connect, status code: ${response.statusCode}';
        });
        print("Login failed with status code: ${response.statusCode}");
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
      print("Error: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white, 
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo at the top
              Image.asset('assets/taplocal.png',
                  width: 150,
                height: 150,), 
              SizedBox(height: 40),

              // Email input
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 12),

              // Password input
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                obscureText: true,
              ),
              SizedBox(height: 12),

              if (_isLoading) CircularProgressIndicator(),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 24),

              Container(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login, 
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    backgroundColor: Colors.black, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: TextStyle(fontSize: 16),
                    foregroundColor: Colors.white, // Set text color to white
                  ),
                  child: Text('Login'),
                ),
              ),
              SizedBox(height: 24),

              // Navigate to Signup page if the user doesn't have an account
              TextButton(
                onPressed: () {
                  // Navigate to signup page
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignupPage()));
                },
                child: Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
