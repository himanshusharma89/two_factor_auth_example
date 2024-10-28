import 'package:flutter/material.dart';
import 'package:firebase_dart_admin_auth_sdk/firebase_dart_admin_auth_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the web api key and project id
  await FirebaseApp.initializeAppWithEnvironmentVariables(
    apiKey: 'AIzaSyBli2c-dmD4w2kLHmZU3UtewETvuruVAN4',
    projectId: 'fire-base-dart-admin-auth-sdk',
    bucketName: 'gs://fire-base-dart-admin-auth-sdk.appspot.com', 
    authdomain: 'localhost', 
    messagingSenderId: '473309149917', 
    appId: '1:473309149917:ios:b7819b37ac576f47a67934'
  );

  FirebaseApp.instance.getAuth();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Admin Auth with 2FA',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserManagementScreen(),
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  FirebaseAuth? firebaseAuth;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController =
      TextEditingController(); // New field for phone number
  final _otpController = TextEditingController(); // New field for OTP
  String _status = "";
  ConfirmationResult? confirmationResult; // Stores verification details for OTP

  @override
  void initState() {
    firebaseAuth = FirebaseApp.firebaseAuth;
    super.initState();
  }

  // Register user and send OTP
  Future<void> registerNewUser() async {
    try {
      // Register user with email and password
      var userCredential = await firebaseAuth?.createUserWithEmailAndPassword(
          _emailController.text, _passwordController.text);

      if (userCredential != null) {
        // Update user role
        firebaseAuth?.updateUserInformation(userCredential.user.uid,
            userCredential.user.idToken!, {'role': _roleController.text});

      final appVerifier = MockApplicationVerifier(); // Replace with actual recaptha verifier
        confirmationResult = await firebaseAuth!.phone.signInWithPhoneNumber(_phoneController.text, appVerifier);
      }

      setState(() {
        _status = "User created successfully. OTP sent for 2FA.";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to create user: $e";
      });
    }
  }

  // Verify OTP
  Future<void> verifyOtp() async {
    if (confirmationResult != null) {
      try {
        await confirmationResult?.confirm(_otpController.text);
        setState(() {
          _status = "OTP verified successfully, user signed in.";
        });
      } catch (e) {
        setState(() {
          _status = "Failed to verify OTP: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management with 2FA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerNewUser,
              child: const Text('Create User and Send OTP'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'Enter OTP'),
            ),
            ElevatedButton(
              onPressed: verifyOtp,
              child: const Text('Verify OTP'),
            ),
            const SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
