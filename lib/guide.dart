import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caroussel/main.dart'; // Importation nécessaire pour MyApp;
import 'package:caroussel/root_app.dart'; // Importation nécessaire pour RootApp





class OnBoardingPage extends StatelessWidget {

   final VoidCallback onDone;
  final VoidCallback onSkip;

  const OnBoardingPage({
    Key? key,
    required this.onDone,
    required this.onSkip,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: [
        ContentConfig(
          title: "🖼️ Choisissez vos images",
          description: "Depuis votre téléphone, en quelques clics.",
          backgroundColor: Colors.blueAccent,
        ),
        ContentConfig(
          title: "🎵 Ajoutez de la musique",
          description: "Depuis vos fichiers ou une liste internet.",
          backgroundColor: Colors.deepPurple,
        ),
        ContentConfig(
          title: "🎬 Générez votre vidéo",
          description: "C’est automatique, vous recevez une notif.",
          backgroundColor: Colors.teal,
        ),
        ContentConfig(
          title: "📂 Où la retrouver ?",
          description: "Cliquez sur la notification pour y accéder.",
          backgroundColor: Colors.green,
        ),
      ],
 onSkipPress: () {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => MyApp(showIntro: false,)),
  );// Pas de sauvegarde, donc le guide reviendra
},
onDonePress: () async {
   final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tutorial_seen', true);

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => RootApp()),
  );
},
    );
  }
}
