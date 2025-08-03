import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnBoardingPage extends StatefulWidget {
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const OnBoardingPage({
    Key? key,
    required this.onDone,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  int _currentIndex = 0;
  bool _animateCurrentSlide = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _animateCurrentSlide = true;
        });
      }
    });
  }

  final List<Color> _backgroundColors = [
    Colors.blueAccent,
    Colors.deepPurple,
    Colors.teal,
    Colors.green,
    Colors.orangeAccent,
  ];

  final List<String> _titles = [
    "🖼️ Choisissez vos images",
    "🎵 Ajoutez votre musique",
    "🎬 Créez votre vidéo",
    "🔔 Recevez une notification",
    "👀 Prévisualisez votre vidéo",

  ];

  final List<String> _descriptions = [
    "Sélectionnez facilement vos photos depuis votre téléphone.",
    "Importez vos musiques préférées ou explorez notre sélection en ligne.",
    "La vidéo se crée automatiquement. Vous serez prévenu(e) une fois prête !",
    "Une alerte s'affiche (appelée notification) : touchez-la pour ouvrir le dossier contenant votre vidéo.",
    "Ou Visualisez votre vidéo avant de la partager avec vos proches.",
    
  ];

  final List<String> _images = [
    "assets/images/choice_images.png",
    "assets/images/add_music.png",
    "assets/images/gener_video.png",
    "assets/images/clic_notif.png",
    "assets/images/preview.png",
  ];

  @override
  Widget build(BuildContext context) {
    final textStyleTitle = GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    final textStyleDesc = GoogleFonts.openSans(
      fontSize: 16,
      color: Colors.white,
    );

    final textStyleAppTitle = GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mon Carrousel',
              style: textStyleAppTitle,
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: IntroSlider(
        listCustomTabs: List.generate(_titles.length, (index) {
          final bool shouldAnimate = (index == _currentIndex && _animateCurrentSlide);

          return Container(
            width: double.infinity,
            color: _backgroundColors[index],
            child: Padding(
              // Le padding peut rester le même, ou être ajusté légèrement
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                // --- MODIFICATION CLÉ : Retour à MainAxisAlignment.center ---
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image principale du slide
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: Center(
                      child: Image.asset(
                        _images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // --- ESPACE ENTRE IMAGE ET TEXTE ---
                  // Ajustez ces valeurs pour obtenir le meilleur équilibre visuel.
                  // Commencez par des valeurs plus petites et augmentez si nécessaire.
                  const SizedBox(height: 30), // Espace après l'image

                  // Titre animé
                  AnimatedOpacity(
                    opacity: shouldAnimate ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _titles[index],
                      style: textStyleTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15), // Espace entre titre et description

                  // Description animée
                  AnimatedOpacity(
                    opacity: shouldAnimate ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _descriptions[index],
                      style: textStyleDesc,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // --- REMARQUE : Le Spacer est supprimé ici ---
                  // Il n'y a plus de Spacer() car MainAxisAlignment.center gère le centrage global.
                ],
              ),
            ),
          );
        }),
        onTabChangeCompleted: (index) {
          setState(() {
            _currentIndex = index;
            _animateCurrentSlide = false;
          });
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() {
                _animateCurrentSlide = true;
              });
            }
          });
        },
        onSkipPress: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('tutorial_seen', true);
          widget.onSkip();
        },
        onDonePress: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('tutorial_seen', true);
          widget.onDone();
        },
        renderNextBtn: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        renderSkipBtn: Row(
          children: const [
            Icon(Icons.skip_next, color: Colors.white),
            SizedBox(width: 6),
            Text('Passer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        renderPrevBtn: const Icon(Icons.arrow_back_ios, color: Colors.white),
        renderDoneBtn: Row(
          children: const [
            Text('Terminé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           /// SizedBox(width: ),
            //Icon(Icons.check_circle_outline, color: Colors.white),
          ],
        ),
       indicatorConfig: IndicatorConfig(
        colorIndicator: Colors.white54,
        colorActiveIndicator: Colors.white,
        sizeIndicator: 10.0,
       ),
        // colorDot: Colors.white54,
        // colorActiveDot: Colors.white,
        // sizeDot: 10.0,
      ),
    );
  }
}