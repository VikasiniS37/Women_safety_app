import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class SafetyRecommendation extends StatefulWidget {
  const SafetyRecommendation({Key? key}) : super(key: key);

  @override
  State<SafetyRecommendation> createState() => _SafetyRecommendationState();
}

class _SafetyRecommendationState extends State<SafetyRecommendation> {
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  double? _distance;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _recommendations;
  String _selectedMode = "Walking";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error fetching location: $e');
      setState(() {
        _errorMessage = "Unable to get location: $e";
      });
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_currentLocation == null || _destinationLocation == null) {
      setState(() {
        _errorMessage = "Please set both the current and destination locations.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final double averageSpeed = _getAverageSpeed(_selectedMode);
    final double travelTime = (_distance! / 1000) / averageSpeed * 60; // in minutes

    final Map<String, dynamic> requestData = {
      "avg_distance": _distance! / 1000, // Convert meters to kilometers
      "travel_time": travelTime,
      "risk_score": 8, // Example risk score
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.131.199:5000/recommend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _recommendations = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch recommendations: ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getAverageSpeed(String mode) {
    switch (mode) {
      case "Car":
        return 60.0;
      case "Bus":
        return 30.0;
      case "Bike":
        return 40.0;
      case "Walking":
      default:
        return 5.0;
    }
  }

  void _setDestination(LatLng point) {
    setState(() {
      _destinationLocation = point;
      _distance = _calculateDistance(_currentLocation!, point);
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = _degToRad(point2.latitude - point1.latitude);
    double dLon = _degToRad(point2.longitude - point1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(point1.latitude)) *
            cos(_degToRad(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Recommendations")),
      body: Column(
        children: [
          if (_currentLocation == null)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: _currentLocation,
                  zoom: 15.0,
                  onTap: (_, point) {
                    _setDestination(point);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Destination set!")),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: _currentLocation!,
                          builder: (_) => const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (_distance != null) Text("Distance: ${_distance!.toStringAsFixed(2)} meters"),
          DropdownButton<String>(
            value: _selectedMode,
            items: const [
              DropdownMenuItem(value: "Walking", child: Text("Walking")),
              DropdownMenuItem(value: "Car", child: Text("Car")),
              DropdownMenuItem(value: "Bike", child: Text("Bike")),
              DropdownMenuItem(value: "Bus", child: Text("Bus")),
            ],
            onChanged: (value) => setState(() => _selectedMode = value!),
          ),
          ElevatedButton(
            onPressed: _fetchRecommendations,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Fetch Recommendations"),
          ),
          if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          if (_recommendations != null)
            Expanded(
              child: ListView(
                children: [
                  Text("Cluster: ${_recommendations!['cluster']}"),
                  ..._recommendations!['safety_tips']
                      .map<Widget>((tip) => Text("- $tip"))
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}