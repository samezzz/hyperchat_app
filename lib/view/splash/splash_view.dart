import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    String route;
    if (!hasSeenWelcome) {
      route = '/welcome';
    } else if (user == null) {
      route = '/login';
    } else {
      // Check onboarding completion in Firestore first
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final firestoreCompleted = userDoc.data()?['hasCompletedOnboarding'] == true;
        if (firestoreCompleted) {
          route = '/home';
        } else {
          route = '/onboarding';
        }
      } catch (e) {
        // Fallback to SharedPreferences if Firestore fails
        final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
        route = hasCompletedOnboarding ? '/home' : '/onboarding';
      }
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 