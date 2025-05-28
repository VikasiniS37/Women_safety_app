import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'sms_util.dart';

class SMSPage extends StatefulWidget {
  const SMSPage({super.key});

  @override
  State<SMSPage> createState() => _SMSPageState();
}

class _SMSPageState extends State<SMSPage> {
  late Position _currentPosition;
  final SMSUtil _smsUtil = SMSUtil();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send SOS Messages')),
      body: Center(
        child: FloatingActionButton(
          onPressed: () {
            _smsUtil.sendSms(
              context: context,
              emergencyStatus: "SOS! This is my current location.",
              currentPosition: _currentPosition,
            );
          },
          backgroundColor: Color(0xFFDA88B3),
          child: const Icon(Icons.message, size: 40.0,color: Colors.black),
            
        ),
      ),
    );
  }
}