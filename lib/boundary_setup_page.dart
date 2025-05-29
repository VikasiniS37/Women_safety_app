import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'sms_util.dart';
import 'dart:math';
import 'dart:async';

class LocationBoundaryPage extends StatefulWidget {
  const LocationBoundaryPage({super.key});

  @override
  State<LocationBoundaryPage> createState() => _LocationBoundaryPageState();
}

class _LocationBoundaryPageState extends State<LocationBoundaryPage> {
  LatLng _currentLocation = LatLng(12.9716, 77.5946); // Default location
  LatLng? _boundaryCenter;
  double? _boundaryRadius;
  late final MapController _mapController;
  Timer? _locationCheckTimer;
  Timer? _sosTimer;

  bool _isOutsideBoundary = false;
  final SMSUtil _smsUtil = SMSUtil();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();

    _locationCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkBoundary();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    _sosTimer?.cancel();
    super.dispose();
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

      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  void _checkBoundary() {
    if (_boundaryCenter != null && _boundaryRadius != null) {
      double distance = _calculateDistance(_currentLocation, _boundaryCenter!);

      if (distance > _boundaryRadius!) {
        if (!_isOutsideBoundary) {
          setState(() {
            _isOutsideBoundary = true;
          });
          _startSOSTimer(distance);
        }
      } else {
        if (_isOutsideBoundary) {
          setState(() {
            _isOutsideBoundary = false;
          });
          _stopSOSTimer();
          debugPrint('User is back inside the boundary.');
        }
      }
    }
  }

  void _startSOSTimer(double distanceFromCenter) {
    _sendSOS(distanceFromCenter);

    _sosTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isOutsideBoundary) {
        _sendSOS(distanceFromCenter);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopSOSTimer() {
    _sosTimer?.cancel();
  }

  Future<void> _sendSOS(double distanceFromCenter) async {
    String emergencyStatus = """
    ALERT! Boundary crossed!
    Distance from center: ${distanceFromCenter.toStringAsFixed(2)} meters.
    """;

    Position position = Position(
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0, 
      altitudeAccuracy: 1.0, 
      headingAccuracy: 1,
      
      

    );

    await _smsUtil.sendSms(
      context: context,
      emergencyStatus: emergencyStatus,
      currentPosition: position,
    );
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

  Future<void> _setBoundaryDetails() async {
    final TextEditingController radiusController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Boundary Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tap on the map to set the center point."),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Enter boundary radius (meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (radiusController.text.isNotEmpty && _boundaryCenter != null) {
                  setState(() {
                    _boundaryRadius = double.tryParse(radiusController.text);
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Boundary set successfully!")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a center point!")),
                  );
                }
              },
              child: const Text("Set"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Boundary')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation,
              zoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _boundaryCenter = point;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Center point set!")),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              if (_boundaryCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _boundaryCenter!,
                      color: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.blue,
                      useRadiusInMeter: true,
                      radius: _boundaryRadius ?? 0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _currentLocation,
                    builder: (ctx) => const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _setBoundaryDetails,
              child: const Icon(Icons.add_location_alt),
            ),
          ),
        ],
      ),
    );
  }
}