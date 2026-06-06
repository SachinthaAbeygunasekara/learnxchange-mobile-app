import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learnxchange/firebase_options.dart';
import 'package:learnxchange/screens/matching/home_screen.dart';
import 'package:learnxchange/screens/auth/login_screen.dart';
import 'package:learnxchange/services/user_service.dart';
import 'package:learnxchange/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnXchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899), // Pink/Magenta accent
        ),
        fontFamily: 'Roboto', // Fallback to Roboto
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          return StreamBuilder<UserModel>(
            stream: UserService().getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (userSnapshot.hasData && userSnapshot.data!.isSuspended) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.block_rounded, color: Colors.red, size: 80),
                          const SizedBox(height: 24),
                          const Text(
                            'Account Suspended',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your account has been suspended by an administrator. Please contact support if you believe this is a mistake.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const HomeScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
