import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:caroussel/pages/privacy.dart';

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

  Function? goToTabFunction;

  final List<Color> _backgroundColors = [
    Colors.blueAccent,
    Colors.deepPurple,
    Colors.teal,
    Colors.green,
    Colors.orangeAccent,
    Colors.indigo,
    Colors.blueGrey[700]!, // Slide Politique
  ];

  final List<String> _titles = [
    "🖼️ Choisissez vos images",
    "🎵 Ajoutez votre musique",
    "🎬 Créez votre vidéo",
    "🔔 Recevez une notification",
    "👀 Prévisualisez votre vidéo",
    "🎉 Prêt à démarrer !",
    "🔒 Respect de votre vie privée", // Slide Politique
  ];

  final List<String> _descriptions = [
    "Sélectionnez vos photos simplement.",
    "Ajoutez votre musique ou explorez notre sélection.",
    "La vidéo se crée automatiquement et vous serez averti·e.",
    "Touchez la notification pour ouvrir votre vidéo.",
    "Visualisez avant de partager avec vos proches.",
    "Vous êtes prêt·e à créer votre première vidéo. Amusez-vous !",
    "Nous respectons votre vie privée et ne collectons aucune donnée personnelle.", // Slide Politique
  ];

  final List<String> _images = [
    "assets/images/choice_images.png",
    "assets/images/add_music.png",
    "assets/images/gener_video.png",
    "assets/images/clic_notif.png",
    "assets/images/preview.png",
    "assets/images/celebration.png",
    "assets/images/privacy.png", // Slide Politique
  ];

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

  void _goToStart() {
    if (goToTabFunction != null) {
      goToTabFunction!(0);
    }
  }

  // Fonction pour charger et afficher le contenu HTML du fichier local
  // Future<void> _showPrivacyPolicy() async {
  //   try {
  //     String htmlContent = await rootBundle.loadString('assets/privacy.html');

  //     // Affiche le contenu dans une boîte de dialogue
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: const Text("Politique de confidentialité"),
  //           content: SingleChildScrollView(
  //             child: Html(data: htmlContent),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('Fermer'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('Erreur de chargement du fichier HTML: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Impossible de charger la politique de confidentialité.')),
  //     );
  //   }
  // }
   void _navigateToPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

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
            Text('Mon Carrousel', style: textStyleAppTitle),
            if (_currentIndex > 0 && _currentIndex < _titles.length - 1) ...[
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: "Revenir au début",
                onPressed: _goToStart,
              ),
            ],
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: IntroSlider(
        refFuncGoToTab: (func) {
          goToTabFunction = func;
        },
        listCustomTabs: List.generate(_titles.length, (index) {
          final bool shouldAnimate = (index == _currentIndex && _animateCurrentSlide);

          return Container(
            width: double.infinity,
            color: _backgroundColors[index],
            child: SafeArea( // Ajout de SafeArea pour éviter que le contenu ne passe sous l'AppBar
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical de tous les éléments
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Center(
                        child: Image.asset(
                          _images[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedOpacity(
                      opacity: shouldAnimate ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _titles[index],
                        style: textStyleTitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    AnimatedOpacity(
                      opacity: shouldAnimate ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _descriptions[index],
                        style: textStyleDesc,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (index == _titles.length - 1) ...[
                      const SizedBox(height: 30), // Ajout d'un petit espace pour la lisibilité
                      TextButton(
                        onPressed: _navigateToPrivacyPolicy,
                        child: Row( // Utilisation d'un Row pour l'icône et le texte
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline, // L'icône a été ajoutée ici
                              color: Colors.lightBlueAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8), // Petit espace entre l'icône et le texte
                            Text(
                              'Politique de confidentialité',
                              style: textStyleDesc.copyWith(
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        onTabChangeCompleted: (index) {
          if (index >= _titles.length) return;
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
            Text('Passer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        renderPrevBtn: const Icon(Icons.arrow_back_ios, color: Colors.white),
        renderDoneBtn: _currentIndex == _titles.length - 1
            ? Row(
                children: const [
                  Text('Terminé',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              )
            : Container(),
        indicatorConfig: IndicatorConfig(
          colorIndicator: Colors.white54,
          colorActiveIndicator: Colors.white,
          sizeIndicator: 10.0,
        ),
      ),
    );
  }
}
