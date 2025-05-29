import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File handling
import 'package:http/http.dart' as http; // HTTP package for API calls
import 'dart:convert'; // For JSON handling
import 'package:geolocator/geolocator.dart'; // For location handling

void main() {
  runApp(MaterialApp(home: UploadAndMapScreen()));
}

class UploadAndMapScreen extends StatefulWidget {
  @override
  _UploadAndMapScreenState createState() => _UploadAndMapScreenState();
}

class _UploadAndMapScreenState extends State<UploadAndMapScreen> {
  File? _selectedImage;
  late MapController _mapController;
  LatLng? _currentLocation;
  final ImagePicker _picker = ImagePicker();
  double? _safetyScore;
  List<Map<String, dynamic>> _safetyLocations = []; // Safety locations from the backend

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation(); // Get the current location when the app starts
    _fetchSafetyLocations(); // Fetch safety locations from the backend
  }

  // Get the current location of the user
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print("Location permission denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  // Fetch safety locations from the backend
  Future<void> _fetchSafetyLocations() async {
    final url = Uri.parse('http://192.168.131.199:5000/get_safety_data'); // Replace with your backend URL
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _safetyLocations = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        print("Failed to fetch safety locations. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching safety locations: $e");
    }
  }

  // Log image picking process and send image confirmation
  Future<void> _pickAndSendImage() async {
    final pickedFile = await _picker.pickImage(
      source: await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ) ?? ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Send Image'),
              onTap: () async {
                Navigator.pop(context);
                await _sendImageToBackend();
              },
            ),
          ],
        ),
      );
    }
  }

  // Send image to the backend for safety score calculation
  Future<void> _sendImageToBackend() async {
    if (_selectedImage != null && _currentLocation != null) {
      final url = Uri.parse('http://192.168.131.199:5000/upload_image'); // Replace with your backend URL

      // Get the current time in ISO format
      final currentTime = DateTime.now().toIso8601String();

      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path))
        ..fields['latitude'] = _currentLocation!.latitude.toString()
        ..fields['longitude'] = _currentLocation!.longitude.toString()
        ..fields['time'] = currentTime; // Send the current time to the backend

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);

        setState(() {
          _safetyScore = data['safety_score'];
        });
        _fetchSafetyLocations(); // Refresh safety locations
      } else {
        print("Failed to get safety score. Status code: ${response.statusCode}");
      }
    }
  }

  // Get marker color based on safety score
  Color _getMarkerColor(double score) {
    if (score >= 90) {
      return Colors.green; // Very safe
    } else if (score >= 75) {
      return Colors.lightGreen; // Safe
    } else if (score >= 50) {
      return Colors.orange; // Moderate
    } else if (score >= 25) {
      return Colors.deepOrange; // Risky
    } else {
      return Colors.red; // Dangerous
    }
  }

  // Show marker details in a dialog
  void _showMarkerDetails(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Image Path: ${location['image_path'] ?? 'N/A'}'),
            Text('Latitude: ${location['latitude']}'),
            Text('Longitude: ${location['longitude']}'),
            Text('Report: ${location['report'] ?? 'N/A'}'),
            Text('Safety Score: ${location['safety_score']}'),
            Text('Time: ${location['time'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Build the legend box
  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(left: 10, bottom: 10),
      width: 200, // Fixed width
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Score Legend',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _legendItem(Colors.green, '90-100 (Very Safe)'),
          SizedBox(height: 6),
          _legendItem(Colors.lightGreen, '75-89 (Safe)'),
          SizedBox(height: 6),
          _legendItem(Colors.orange, '50-74 (Moderate)'),
          SizedBox(height: 6),
          _legendItem(Colors.deepOrange, '25-49 (Risky)'),
          SizedBox(height: 6),
          _legendItem(Colors.red, '0-24 (Dangerous)'),
        ],
      ),
    );
  }

  // Build a single legend item
  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image and View Map')),
      body: Stack(
        children: [
          if (_currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentLocation,
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // Current location marker
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        builder: (context) => Icon(Icons.location_on, color: Colors.blue, size: 40),
                      ),
                    // Safety locations markers
                    ..._safetyLocations.map((location) {
                      final safetyScore = location['safety_score'];
                      return Marker(
                        point: LatLng(location['latitude'], location['longitude']),
                        builder: (context) => GestureDetector(
                          onTap: () => _showMarkerDetails(location),
                          child: Icon(
                            Icons.location_on,
                            color: _getMarkerColor(safetyScore),
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _buildLegend(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndSendImage,
        child: Icon(Icons.camera),
        tooltip: 'Pick and Send Image',
      ),
    );
  }
}
