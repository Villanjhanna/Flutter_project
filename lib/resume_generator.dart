import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  _ResumeScreenState createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _isSubmitting = false;
  bool _isPdfGenerated = false;
  String? _pdfPath;

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<void> generateResumePdf() async {
    try {
      final pdf = pw.Document();

      // Define styles for sections and text
      final pw.TextStyle headerStyle = pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
      );
      final pw.TextStyle sectionTitleStyle = pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(0xFF1C1C1C), // Darker color for section titles
      );
      final pw.TextStyle contentStyle = pw.TextStyle(
        fontSize: 12,
        color: PdfColor.fromInt(0xFF333333), // Slightly darker content text
      );
      final pw.TextStyle boldContentStyle = pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: Full Name, Email, Phone Number
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      _nameController.text,
                      style: headerStyle,
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Email: ${_emailController.text}',
                            style: contentStyle),
                        pw.Text('Phone: ${_phoneController.text}',
                            style: contentStyle),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),

                // Address Section
                pw.Text('Address', style: sectionTitleStyle),
                pw.Text(_addressController.text, style: contentStyle),
                pw.SizedBox(height: 15),

                // Professional Summary
                pw.Text('Professional Summary', style: sectionTitleStyle),
                pw.Text(_summaryController.text, style: contentStyle),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 15),

                // Work Experience
                pw.Text('Work Experience', style: sectionTitleStyle),
                pw.Text(_experienceController.text, style: contentStyle),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 15),

                // Education Section
                pw.Text('Education', style: sectionTitleStyle),
                pw.Text(_educationController.text, style: contentStyle),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 15),

                // Skills Section
                pw.Text('Skills', style: sectionTitleStyle),
                pw.Text(_skillsController.text, style: contentStyle),
                pw.SizedBox(height: 20),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/resume.pdf';
      final file = File(filePath);

      // Ensure that the file is being written properly
      await file.writeAsBytes(await pdf.save());

      if (await file.exists()) {
        await OpenFile.open(filePath);
      } else {
        log('Failed to create file at $file');
      }

      setState(() {
        _pdfPath = file.path;
        _isPdfGenerated = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('resume_path', _pdfPath!);
      print('PDF generated at: ${file.path}');
      print('Is PDF generated: $_isPdfGenerated');
      print('PDF Path: $_pdfPath');
    } catch (e) {
      print("Error generating PDF: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Future<void> submitResume() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No resume generated yet')));
      return;
    }

    final String apiUrl = 'https://s2010681.helioho.st/submit_resume.php';

    int? userId = await getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User not logged in')));
      return;
    }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['user_id'] = userId.toString();

    request.files.add(await http.MultipartFile.fromPath('resume', _pdfPath!));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var data = json.decode(responseData.body);

        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Resume submitted successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(data['message'] ?? 'Failed to submit resume')));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to submit resume')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> saveResume() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final String apiUrl =
          'https://s2010681.helioho.st/store_user_details.php';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: {
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'summary': _summaryController.text,
            'experience': _experienceController.text,
            'education': _educationController.text,
            'skills': _skillsController.text,
          },
        );

        final responseData = json.decode(response.body);

        if (response.statusCode == 200 && responseData['success'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resume saved successfully!')),
          );

          await generateResumePdf();

          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _addressController.clear();
          _summaryController.clear();
          _experienceController.clear();
          _educationController.clear();
          _skillsController.clear();

          setState(() {
            _isPdfGenerated = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save resume.')),
          );
        }
      } catch (e) {
        print("Error during HTTP request: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving resume: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildTextFormField(_nameController, 'Full Name'),
              _buildTextFormField(_emailController, 'Email'),
              _buildTextFormField(_phoneController, 'Phone Number'),
              _buildTextFormField(_addressController, 'Address'),
              SizedBox(height: 20),
              Text('Professional Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildTextFormField(_summaryController, 'Summary', maxLines: 5),
              SizedBox(height: 20),
              Text('Work Experience',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildTextFormField(_experienceController, 'Experience',
                  maxLines: 5),
              SizedBox(height: 20),
              Text('Education',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildTextFormField(_educationController, 'Education',
                  maxLines: 5),
              SizedBox(height: 20),
              Text('Skills',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildTextFormField(_skillsController, 'Skills', maxLines: 5),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : saveResume,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text('Save Resume', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: (_isPdfGenerated && _pdfPath != null)
                      ? () {
                          submitResume(); // Submit the resume to the server
                        }
                      : null, // Disable the button until the PDF is generated
                  child: Text('Submit Resume'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields
  Widget _buildTextFormField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;
  const PdfViewerScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume PDF View"),
      ),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}
