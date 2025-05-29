import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'sms_util.dart'; // Import SMS utility

class CrimeSpotMap extends StatefulWidget {
  const CrimeSpotMap({Key? key}) : super(key: key);

  @override
  State<CrimeSpotMap> createState() => _CrimeSpotMapState();
}

class _CrimeSpotMapState extends State<CrimeSpotMap> {
  LatLng _currentLocation = LatLng(12.9716, 77.5946); // Default location
  late final MapController _mapController;
  List<Map<String, dynamic>> _crimeData = []; // List to hold crime data
  bool _alertSent = false; // Prevent duplicate alerts

  final SMSUtil smsUtil = SMSUtil(); // Initialize SMS utility

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  // Fetch the current location of the user
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentLocation, 15.0); // Moves map to location
        });

        // Generate fake crime data based on current location
        _crimeData = generateFakeCrimeData(_currentLocation.latitude, _currentLocation.longitude);

        // Check if user is entering a crime hotspot
        _checkAndNotifyIfInHotspot(_currentLocation.latitude, _currentLocation.longitude, position);
      });
    }
  }


  // Generate fake crime data for demonstration
  List<Map<String, dynamic>> generateFakeCrimeData(
      double userLat, double userLon) {
    List<Map<String, dynamic>> crimeData = [];

    for (int i = 0; i < 5; i++) {
      double latOffset = Random().nextDouble() * 0.002 - 0.001;
      double lonOffset = Random().nextDouble() * 0.002 - 0.001;
      double crimeLat = userLat + latOffset;
      double crimeLon = userLon + lonOffset;

      List<String> crimeTypes = [
        "Murder",
        "Rape",
        "Robbery",
        "Assault",
        "Traffic Violence",
        "Disorderly Conduct"
      ];
      String crimeName = crimeTypes[Random().nextInt(crimeTypes.length)];

      DateTime now = DateTime.now();
      DateTime randomDate =
          now.subtract(Duration(days: Random().nextInt(365 * 4)));
      String dateStr =
          "${randomDate.year}-${randomDate.month.toString().padLeft(2, '0')}-${randomDate.day.toString().padLeft(2, '0')}";
      String timeStr =
          "${Random().nextInt(24).toString().padLeft(2, '0')}:${Random().nextInt(60).toString().padLeft(2, '0')}";

      crimeData.add({
        "latitude": crimeLat,
        "longitude": crimeLon,
        "crime_name": crimeName,
        "date": dateStr,
        "time": timeStr
      });
    }
    return crimeData;
  }

  // Calculate distance between two coordinates
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371000; // Earth's radius in meters
    double phi1 = lat1 * pi / 180;
    double phi2 = lat2 * pi / 180;
    double deltaPhi = (lat2 - lat1) * pi / 180;
    double deltaLambda = (lon2 - lon1) * pi / 180;

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) *
            sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radiusOfEarth * c;
  }

  // Check if the user is in a crime hotspot and send alert
  void _checkAndNotifyIfInHotspot(
      double userLat, double userLon, Position currentPosition) {
    for (var crime in _crimeData) {
      double crimeLat = crime['latitude'];
      double crimeLon = crime['longitude'];
      double distance = calculateDistance(userLat, userLon, crimeLat, crimeLon);

      if (distance <= 300 && !_alertSent) {
        _showWarningDialog(crime['crime_name']);
        smsUtil.sendSms(
          context: context,
          emergencyStatus:
              "You are in a crime hotspot: ${crime['crime_name']}.",
          currentPosition: currentPosition,
        );
        _alertSent = true;
        break;
      }
    }
  }

  // Show warning dialog
  void _showWarningDialog(String crimeName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning!'),
          content: Text('You have entered a crime hotspot: $crimeName'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Location Tracking with Crime Data')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _currentLocation,
          zoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation,
                builder: (context) => const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
              ..._crimeData.map((crime) {
                Color markerColor = crime['crime_name'] == "Murder" || crime['crime_name'] == "Rape" ? Colors.red : Colors.orange;
                return Marker(
                  point: LatLng(crime['latitude'], crime['longitude']),
                  builder: (context) => Icon(
                    Icons.warning,
                    color: markerColor,
                    size: 40.0,
                  ),
                );
              }).toList(),
            ],
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: _currentLocation,
                radius: 300,
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}