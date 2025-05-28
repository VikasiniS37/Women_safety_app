import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SMSUtil {
  // Load Twilio credentials from .env
  final String accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  final String authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  final String twilioPhoneNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

  Future<List<String>> getEmergencyContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return List.generate(
      5,
      (index) => prefs.getString('emergencyContact$index') ?? "",
    ).where((contact) => contact.isNotEmpty).toList();
  }

  Future<void> sendSms({
    required BuildContext context,
    required String emergencyStatus,
    required Position currentPosition,
  }) async {
    List<String> emergencyContacts = await getEmergencyContacts();

    if (emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No emergency contacts found!")),
      );
      return;
    }

    for (String contact in emergencyContacts) {
      String message = """
      Emergency: $emergencyStatus
      Track the current location: https://www.google.com/maps?q=${currentPosition.latitude},${currentPosition.longitude}
      """;

      final url = Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
        },
        body: {
          'From': twilioPhoneNumber,
          'To': contact,
          'Body': message,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('SMS sent successfully to $contact!');
      } else {
        debugPrint(
            'Failed to send SMS to $contact: ${response.statusCode}, ${response.body}');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS Messages sent successfully!")),
    );
  }
}
