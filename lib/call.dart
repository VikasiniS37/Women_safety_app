import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  List<String> _emergencyContacts = [];

  final String accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  final String authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  final String twilioPhoneNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

  @override
  void initState() {
    super.initState();
    _getEmergencyContacts();
  }

  Future<void> _getEmergencyContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContacts = List.generate(
        5,
        (index) => prefs.getString('emergencyContact$index') ?? "",
      ).where((contact) => contact.isNotEmpty).toList();
    });
  }

  Future<void> makeCall() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contacts found!")),
      );
      return;
    }

    String emergencyContact = _emergencyContacts[0]; // Use the first contact
    String callUrl =
        'https://9d25-2401-4900-67a7-e9ac-7dad-d6e7-f1f0-820b.ngrok-free.app/alert';

    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Calls.json');
    final response = await http.post(
      url,
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {
        'From': twilioPhoneNumber,
        'To': emergencyContact,
        'Url': callUrl, // URL with TwiML instructions for the call
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('Call initiated successfully to $emergencyContact!');
    } else {
      debugPrint(
          'Failed to initiate call to $emergencyContact: ${response.statusCode}, ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Call')),
      body: Center(
        child: FloatingActionButton(
          onPressed: makeCall,
          backgroundColor: Color(0xFFDA88B3),
          child: const Icon(
            Icons.call,
            size: 40.0,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
