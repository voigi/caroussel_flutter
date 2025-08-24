import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool privacyAccepted = false;
  Function? goToTabFunction;

  final List<Color> _backgroundColors = [
    Colors.blueAccent,
    Colors.deepPurple,
    Colors.teal,
    Colors.green,
    Colors.orangeAccent,
    Colors.indigo,
    const Color.fromARGB(255, 231, 97, 56), // Slide Politique
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
    "Nous respectons votre vie privée et ne collectons aucune donnée personnelle.",
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
    _loadPrivacyState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _animateCurrentSlide = true;
        });
      }
    });
  }

  void _loadPrivacyState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
    });
  }

  void _goToStart() {
    if (goToTabFunction != null) {
      goToTabFunction!(0);
    }
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    ).then((accepted) {
      if (accepted == true) {
        setState(() {
          privacyAccepted = true; // Met à jour l'état si l'utilisateur accepte
        });
      }
    });
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
        //si privacyAccepted est true, on n'affiche pas le bouton retour
        automaticallyImplyLeading: _currentIndex > 0 && !privacyAccepted,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(left:10.0),
          child: Row(
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
      ),
      extendBodyBehindAppBar: true,
      body: IntroSlider(
        refFuncGoToTab: (func) {
          goToTabFunction = func;
        },
        listCustomTabs: List.generate(_titles.length, (index) {
          final bool shouldAnimate =
              (index == _currentIndex && _animateCurrentSlide);

          return Container(
            width: double.infinity,
            color: _backgroundColors[index],
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 30),
                    if (!privacyAccepted)
                      ElevatedButton.icon(
                        onPressed: _navigateToPrivacyPolicy,
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        label: const Text("Lire la politique"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        //si l'utilisateur a dejà accepté la politique, on active le bouton, pour cela on memorise l'etat de celui ci dans shared_preferences
                        onPressed: privacyAccepted
                            ? () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('privacy_accepted', true);
                                await prefs.setBool('tutorial_seen', true);
                                widget.onDone();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Commencer'),
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
       
        renderNextBtn: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        renderPrevBtn: const Icon(Icons.arrow_back_ios, color: Colors.white),
        // renderSkipBtn: Row(
        //   children: const [
        //     Icon(Icons.skip_next, color: Colors.white),
        //     SizedBox(width: 6),
        //     Text('Passer',
        //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        //   ],
        // ),
       
        isShowSkipBtn: false,
        isShowDoneBtn: false, // Pas de bouton "Done": // plus d'ombre ni bouton
        indicatorConfig: IndicatorConfig(
          colorIndicator: Colors.white54,
          colorActiveIndicator: Colors.white,
          sizeIndicator: 10.0,
        ),
      ),
    );
  }
}