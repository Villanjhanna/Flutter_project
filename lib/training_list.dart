import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key});

  @override
  _TrainingsScreenState createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true; // Variable to track loading state
  String errorMessage = ''; // Variable to store error message if any

  @override
  void initState() {
    super.initState();
    _fetchTrainings();
  }

  // Method to fetch training data
  _fetchTrainings() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://s2010681.helioho.st/TapLocal_Web/TapLocal_Web/backend/fetch_trainings.php'),
      );

      // Log the raw response for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Content-Type: ${response.headers['content-type']}');

      // Check if the response status code is 200
      if (response.statusCode == 200) {
        // Check if the response content-type is JSON
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          try {
            // Try to decode the response body into a list
            List data = jsonDecode(response.body);

            if (data is List && data.isNotEmpty) {
              setState(() {
                trainings = List<Map<String, dynamic>>.from(data);
                isLoading = false;
              });
            } else {
              setState(() {
                errorMessage = 'No trainings found or invalid data format';
                isLoading = false;
              });
            }
          } catch (e) {
            setState(() {
              errorMessage = 'Failed to parse response: $e';
              isLoading = false;
            });
            print('Error parsing response: $e');
          }
        } else {
          setState(() {
            errorMessage = 'Invalid response format from server';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load trainings. HTTP Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching trainings: $e';
        isLoading = false;
      });
      print('Error fetching trainings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : trainings.isEmpty
                  ? Center(child: Text('No trainings available'))
                  : ListView.builder(
                      itemCount: trainings.length,
                      itemBuilder: (context, index) {
                        final training = trainings[index];
                        return Card(
                          margin: EdgeInsets.all(10),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  training['title'] ?? 'No Title',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Date: ${training['date'] ?? 'No Date'}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blue),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Time: ${training['time'] ?? 'No Time'}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blue),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Location: ${training['location'] ?? 'No Location'}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blue),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Description: ${training['description'] ?? 'No Description'}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Slots Available: ${training['slots'] ?? '0'}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.green),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TrainingDetailsScreen(
                                                training: training),
                                      ),
                                    );
                                  },
                                  child: Text('Reserve Slot'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class TrainingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> training;

  const TrainingDetailsScreen({super.key, required this.training});

  @override
  _TrainingDetailsScreenState createState() => _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends State<TrainingDetailsScreen> {
  String? errorMessage;
  bool isLoading = false;
  bool isReserved = false; // Track reservation status

  // Method to fetch user ID from SharedPreferences
  Future<int?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<void> _reserveSlot() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Fetch the user ID dynamically from SharedPreferences
    int? userId = await _getUserId();
    if (userId == null) {
      setState(() {
        errorMessage = 'User is not logged in!';
        isLoading = false;
      });
      return;
    }

    int trainingId = widget.training['training_id'];

    try {
      final response = await http.post(
        Uri.parse('http://s2010681.helioho.st/reserve_slot.php'),
        body: {
          'user_id': userId.toString(),
          'training_id': trainingId.toString(),
        },
      );

      // Log the response body for debugging
      print('Response Body: ${response.body}');
      print('Response Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        // Check if the response content-type is JSON
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          // Try to parse the JSON response
          try {
            Map<String, dynamic> responseBody = jsonDecode(response.body);

            // Assuming the response contains a 'message' key
            if (responseBody['message'] == 'Reservation confirmed!') {
              setState(() {
                isReserved = true;
                widget.training['slots']--; // Decrement available slots
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reservation confirmed!')),
              );
            } else {
              setState(() {
                errorMessage =
                    responseBody['error'] ?? 'Failed to reserve slot';
              });
            }
          } catch (e) {
            setState(() {
              errorMessage = 'Failed to parse response: $e';
            });
            print('Error parsing response: $e');
          }
        } else {
          setState(() {
            errorMessage =
                'Unexpected content type: ${response.headers['content-type']}';
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to reserve slot. HTTP Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error reserving slot: $e';
      });
      print('Error reserving slot: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.training['title']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${widget.training['date']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Time: ${widget.training['time']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Location: ${widget.training['location']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Description: ${widget.training['description']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Slots Available: ${widget.training['slots']}',
                style: TextStyle(fontSize: 16)),
            if (errorMessage != null) ...[
              SizedBox(height: 10),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
            if (isReserved) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Your reservation has been successfully confirmed!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: widget.training['slots'] > 0 && !isReserved
                        ? _reserveSlot
                        : null,
                    style: ElevatedButton.styleFrom(
                      iconColor: Colors.blue, // Button color
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child:
                        Text(isReserved ? 'Reserved' : 'Confirm Reservation'),
                  ),
          ],
        ),
      ),
    );
  }
}
