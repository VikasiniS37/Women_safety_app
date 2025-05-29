import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IncidentReportScreen(),
    );
  }
}

class IncidentReportScreen extends StatefulWidget {
  @override
  _IncidentReportScreenState createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  late stt.SpeechToText _speech;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController incidentDescriptionController = TextEditingController();
  String _generatedReport = "";
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeechRecognizer();
  }

  Future<void> _initializeSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {
        print("Speech recognition error: $error");
      },
    );
    if (!available) {
      print("Speech recognition is not available on this device.");
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          incidentDescriptionController.text = result.recognizedWords;
        });
      },
      listenFor: Duration(minutes: 2),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
    );
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _speech.stop();
  }

  Future<void> _generateReport() async {
    final String date = dateController.text.trim();
    final String time = timeController.text.trim();
    final String location = locationController.text.trim();
    final String description = incidentDescriptionController.text.trim();

    if (description.isEmpty || date.isEmpty || time.isEmpty || location.isEmpty) {
      setState(() {
        _generatedReport = "Please fill in all the fields to generate the report.";
      });
      return;
    }

    // Send data to the backend for report generation
    final response = await _sendToBackend(date, time, location, description);

    if (response != null && response['generated_report'] != null) {
      setState(() {
        _generatedReport = response['generated_report'];
      });
    } else {
      setState(() {
        _generatedReport = "Failed to generate report. Please try again.";
      });
    }
  }

  Future<Map<String, dynamic>?> _sendToBackend(String date, String time, String location, String description) async {
    final Uri apiUrl = Uri.parse('http://192.168.14.220:5000/generate-report');
    // Replace with your backend URL

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'user_input': description,
          'location': location,
          'time': time,
          'date': date,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print("Error sending data to backend: $e");
      return null;
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text = DateFormat('MMMM dd, yyyy').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Incident Report Generator"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: _startRecording,
                onLongPressUp: _stopRecording,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Press and hold the mic button to record the incident description.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: incidentDescriptionController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Incident Description",
                  border: OutlineInputBorder(),
                  hintText: "Type or speak the incident description here...",
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: "Time (e.g., 5:30 PM)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateReport,
                child: Text("Generate Report"),
              ),
              SizedBox(height: 20),
              Text(
                "Generated Report:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _generatedReport.isEmpty
                      ? "The generated report will appear here."
                      : _generatedReport,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    incidentDescriptionController.dispose();
    super.dispose();
  }
}
