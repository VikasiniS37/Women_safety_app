import 'package:flutter/material.dart';
import 'sms.dart'; // Import SMS Page
import 'call.dart'; // Import Call Page
import 'boundary_setup_page.dart'; // Import Geofence Page
import 'emergency_contacts_page.dart'; // Import Emergency Contacts Page
import 'crime_spot.dart'; // Import Crime Spot Map Page
import 'time_butt.dart'; // Import Time Calculation Page
import 'botrun.dart'; // Import Chatbot Page
import 'safety_recom.dart'; // Import Safety Recommendation Page
import 'safety_score.dart'; // Import Safety Score Page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/sms': (context) => SMSPage(),
        '/call': (context) => CallPage(),
        '/geofence': (context) => LocationBoundaryPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFB71C83)),
            onPressed: _toggleDrawer,
          ),
          centerTitle: true,
          title: const Text(
            "AVAL",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C83),
              fontFamily: 'Roboto',
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(2.0),
            child: Divider(
              color: Color(0xFFB71C83),
              thickness: 2,
              height: 0,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _closeDrawer,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/womens_2.png',
                      width: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: "Your safety companion ",
                      style: TextStyle(
                        color: Color(0xFFB71C83),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                      children: [
                        TextSpan(
                          text: "wherever \n",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: "you go",
                          style: TextStyle(color: Color(0xFFB71C83)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      CircleButton(
                        icon: Icons.emergency,
                        label: "SOS Message",
                        onTap: () => _navigateTo(context, SMSPage()),
                      ),
                      CircleButton(
                        icon: Icons.phone,
                        label: "Call",
                        onTap: () => _navigateTo(context, CallPage()),
                      ),
                      CircleButton(
                        icon: Icons.mic,
                        label: "Code Word",
                        onTap: () => _navigateTo(context, VoiceDetectionPage()),
                      ),
                      CircleButton(
                        icon: Icons.visibility_off,
                        label: "Crime Area",
                        onTap: () => _navigateTo(context, CrimeSpotMap()),
                      ),
                      
                      CircleButton(
                        icon: Icons.location_pin,
                        label: "Geofence",
                        onTap: () => _navigateTo(context, LocationBoundaryPage()),
                      ),
                      
                      
                      CircleButton(
                        icon: Icons.shield,
                        label: "Safety Score",
                        onTap: () {
                          // Add navigation or functionality
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UploadAndMapScreen()),
                          );
                        },
                      ),
                      CircleButton(
                        icon: Icons.tips_and_updates_rounded,
                        label: "Safety Tips",
                        onTap: () => _navigateTo(context, const SafetyRecommendation()),
                      ),
                      CircleButton(
                        icon: Icons.document_scanner,
                        label: "Make a Report",
                        onTap: () {
                          // Add navigation or functionality
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFB71C83),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatbotPage()),
                );
              },
              child: const Icon(Icons.chat, color: Colors.white),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isDrawerOpen ? 0 : -MediaQuery.of(context).size.width * 0.7,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: Colors.pink.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildDrawerButton("Home", Icons.home, () {
                    _closeDrawer();
                  }),
                  _buildDrawerButton("Account", Icons.account_circle, () {
                    _closeDrawer();
                  }),
                  _buildDrawerButton("Emergency Contact", Icons.contacts, () {
                    _navigateTo(context, const EmergencyContactPage());
                    _closeDrawer();
                  }),
                  _buildDrawerButton("Logout", Icons.logout, () {
                    _closeDrawer();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFDA88B3),
            child: Icon(
              icon,
              size: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}