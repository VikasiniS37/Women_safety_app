import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'sms_util.dart'; // Import your SMSUtil file here

class VoiceDetectionPage extends StatefulWidget {
  @override
  _VoiceDetectionPageState createState() => _VoiceDetectionPageState();
}

class _VoiceDetectionPageState extends State<VoiceDetectionPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final SMSUtil _smsUtil = SMSUtil();
  bool isListening = false;
  String detectedMessage = '';

  int selectedTime = 15; // Default time in minutes
  String selectedCodeWord = 'may day'; // Default code word
  Timer? _timer;

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        isListening = true;
        detectedMessage = '';
      });

      _speech.listen(
        onResult: (result) async {
          String recognizedWords = result.recognizedWords.toLowerCase().trim();
          print("Recognized speech: $recognizedWords"); // Debugging the input

          if (recognizedWords.contains(selectedCodeWord.toLowerCase())) {
            _speech.stop();
            _timer?.cancel();
            setState(() {
              isListening = false;
            });
            await _sendSOS(); // Send the SOS message
          }
        },
        listenFor: Duration(minutes: selectedTime),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        onSoundLevelChange: (level) => print('Sound level: $level'),
      );

      _timer = Timer(Duration(minutes: selectedTime), () {
        if (isListening) {
          _stopListening();
          setState(() {
            detectedMessage = "Time's up. Listening stopped.";
          });
        }
      });
    }
  }

  Future<void> _sendSOS() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await _smsUtil.sendSms(
        context: context,
        emergencyStatus: "Codeword '$selectedCodeWord' detected.",
        currentPosition: currentPosition,
      );
    } catch (e) {
      print("Error sending SOS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send SOS message!")),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    _timer?.cancel();
    setState(() {
      isListening = false;
      detectedMessage = "Listening stopped.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Detection',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.pink, width: 2.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select the recording time and codeword, then press Set to start.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: selectedTime,
              items: [15, 30, 45]
                  .map((time) => DropdownMenuItem(
                value: time,
                child: Text('$time minutes'),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTime = value ?? 15;
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedCodeWord,
              items: [
                'may day',
                'dr brown',
                'ask for ani',
                'ask for angela'
              ]
                  .map((word) => DropdownMenuItem(
                value: word,
                child: Text(word),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCodeWord = value ?? 'may day';
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isListening ? null : _startListening,
              child: const Text('Set and Start Listening'),
            ),
            const SizedBox(height: 20),
            if (detectedMessage.isNotEmpty)
              Center(
                child: Text(
                  detectedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}