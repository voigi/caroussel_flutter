import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'guide.dart'; // ton fichier OnBoardingPage
// ton provider
import 'package:caroussel/main.dart'; // ton MyApp principal


class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool? tutorialSeen;

  @override
  void initState() {
    super.initState();
    _checkTutorialSeen();
  }

  Future<void> _checkTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen') ?? false;
    setState(() {
      tutorialSeen = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tutorialSeen == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!tutorialSeen!) {
      return MaterialApp(
        home: OnBoardingPage(
          onDone: _onTutorialDone,
          onSkip: _onTutorialDone,
        ),
      );
    }

    return 
    
       MaterialApp(
        home: MyApp( showIntro: false), // Passer showIntro comme false
        debugShowCheckedModeBanner: false, // Optionnel, pour enlever le banner de debug
      );
    
  }

  void _onTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    setState(() {
      tutorialSeen = true;
    });
  }
}
