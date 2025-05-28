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
    // Construct the image path directly from the 'uploads' folder
    String imagePath = 'lib/' + location['image_path'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Image (if exists)
              Image.asset(
                imagePath,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text('Image not available');
                },
              ),
              SizedBox(height: 15),

              // Safety Score Section with Legend
              Text(
                'Safety Score:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              _safetyScoreLegend(
                _getSafetyScoreColor(location['safety_score']),
                '${location['safety_score']} (${_getSafetyScoreCategory(location['safety_score'])})',
              ),
              SizedBox(height: 20),

              // Issues Section
              Text(
                'Issues:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              _displayContentAsPoints(location['report'], 'Issues:'),

              // Recommendations Section
              SizedBox(height: 15),
              Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              _displayContentAsPoints(location['report'], 'Recommendations:'),

              // Time Section
              SizedBox(height: 15),
              Text(
                'Time:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                location['time'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),

              // Close Button
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Renamed function to _safetyScoreLegend
  Widget _safetyScoreLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

// Function to determine safety score color
  Color _getSafetyScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.deepOrange;
    return Colors.red;
  }

// Function to determine safety score category
  String _getSafetyScoreCategory(double score) {
    if (score >= 90) return 'Very Safe';
    if (score >= 75) return 'Safe';
    if (score >= 50) return 'Moderate';
    if (score >= 25) return 'Risky';
    return 'Dangerous';
  }

// Helper function to extract and display content as points
  Widget _displayContentAsPoints(String report, String section) {
    // Extract the relevant section (Issues or Recommendations)
    String extractedContent = report
        .split(section)[1]
        .split(section == 'Issues:' ? 'Recommendations:' : 'Time:')[0]
        .trim();

    // Split content into points by '\n-' and display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: extractedContent
          .split('\n-')
          .map((point) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '- $point',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
      ))
          .toList(),
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
                            size: 50, // Larger size for better visibility
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
