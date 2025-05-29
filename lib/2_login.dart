import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:firebase_core/firebase_core.dart'; // Ensure Firebase is initialized
import 'home_page.dart'; // Import home page after login
import 'signup_page.dart'; // Import signup page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10), // Minimal spacing below the AppBar
              Image.asset(
                'assets/logo_remov.jpg', // Path to your image in the assets folder
                width: 200, // Adjusted width for better placement
                height: 200, // Adjusted height for better placement
              ),
              SizedBox(height: 2), // Minimal spacing between logo and text fields
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10, // Length is now 10 digits (without country code)
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Only allow digits
                  ],
                  decoration: InputDecoration(
                    hintText: 'Phone Number (e.g. 877xxxxxxx)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    errorText: _phoneError,
                  ),
                ),
              ),
              SizedBox(height: 10), // Reduced spacing between text fields
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon: Icon(
                      Icons.key_sharp,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10), // Reduced spacing between text field and button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () async {
                    String phone = _phoneController.text;
                    String password = _passwordController.text;

                    // Validate the phone number and password
                    if (phone.isEmpty || phone.length != 10) {
                      setState(() {
                        _phoneError = 'Enter a valid 10-digit phone number';
                      });
                    } else if (password.isEmpty || password.length < 6) {
                      setState(() {
                        _passwordError = 'Password must be at least 6 characters';
                      });
                    } else {
                      setState(() {
                        _phoneError = null;
                        _passwordError = null;
                      });

                      try {
                        // Format the phone number into the required email format
                        String formattedPhone = '+91$phone@aval.com';

                        // Login using Firebase Authentication
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: formattedPhone,
                          password: password,
                        );

                        // Navigate to home page after successful login
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      } catch (e) {
                        setState(() {
                          _phoneError = 'Failed to log in. Please check your credentials';
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    backgroundColor: Colors.pink,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 10), // Reduced spacing between button and text
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage()),
                  );
                },
                child: Text(
                  'Don\'t have an account? Sign up',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
