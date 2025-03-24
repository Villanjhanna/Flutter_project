import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JobListScreen extends StatefulWidget {
  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Map<String, dynamic>> jobs = [];
  bool isLoading = true;
  String errorMessage = '';
  int? userId;

  // Fetch job data from the API
  Future<void> fetchJobs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        errorMessage = 'User not logged in';
        isLoading = false;
      });
      return;
    }

    final String apiUrl =
        'http://s2010681.helioho.st/get_joblist.php?user_id=$userId';
    print("API URL: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            errorMessage = 'No jobs found for the user.';
            isLoading = false;
          });
          return;
        }

        // Decode the response body as a Map
        Map<String, dynamic> data = json.decode(response.body);

        // Check if the response contains the 'jobs' key and its value is a List
        if (data.containsKey('jobs') && data['jobs'] is List) {
          List<dynamic> jobList = data['jobs'];

          if (jobList.isEmpty) {
            setState(() {
              errorMessage = 'No jobs found for the user.';
              isLoading = false;
            });
          } else {
            setState(() {
              jobs = jobList.map((job) {
                return {
                  'id': job['id'] ?? 'No ID',
                  'title': job['title'] ?? 'No title',
                  'company_name': job['company_name'] ?? 'No company',
                  'location': job['location'] ?? 'No location',
                  'description': job['description'] ?? 'No description',
                  'salary': job['salary'] ?? 'Not available',
                  'responsibilities': job['responsibilities'] ?? 'Not listed',
                  'qualifications': job['qualifications'] ?? 'Not listed',
                };
              }).toList();
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'Invalid response format: No jobs found.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load jobs, Status Code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching jobs: $e';
        isLoading = false;
      });
      print("Error fetching jobs: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return JobCard(job: jobs[index]);
                  },
                ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job['title'] as String? ?? 'No title',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              job['company_name'] as String? ?? 'No company',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 5),
            Text(
              job['location'] as String? ?? 'No location',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 10),
            Text(
              job['description'] as String? ?? 'No description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(job: job),
                  ),
                );
              },
              child: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  JobDetailScreen({required this.job});

  Future<void> applyForJob(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? resumePath = prefs.getString('resume_path');

      if (resumePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume not found! Please upload your resume first.')),
        );
        return;
      }

      int userId = prefs.getInt('user_id') ?? -1;

      if (userId == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in! Please log in first.')),
        );
        return;
      }

      final String apiUrl = 'https://s2010681.helioho.st/apply_job.php';

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['user_id'] = userId.toString();
      request.fields['job_id'] = job['id'].toString();

      // Attach the resume file
      request.files.add(await http.MultipartFile.fromPath('resume', resumePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = json.decode(responseBody);

        if (responseJson['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully applied for the job!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to apply for the job. Please try again later.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply for the job. Please try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying for job: $e')),
      );
      print('Error applying for job: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job['title'] ?? 'No Title'),  
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              job['title'] ?? 'No title',  
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              job['company_name'] ?? 'No company',  
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 5),
            Text(
              job['location'] ?? 'No location', 
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 20),
            Text(
              job['description'] ?? 'No description', 
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Salary: ${job['salary'] ?? 'Not available'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Responsibilities: ${job['responsibilities'] ?? 'Not listed'}',  
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Qualifications: ${job['qualifications'] ?? 'Not listed'}',  
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                applyForJob(context);
              },
              child: Text('Apply Now'),
            ),
          ],
        ),
      ),
    );
  }
}
