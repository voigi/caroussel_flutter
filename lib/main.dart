import 'package:caroussel/notif.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importez ce package
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // Importez le fichier généré par FlutterFire
import 'package:caroussel/media_uploader.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';
import 'drawer_settings_provider.dart';
import 'package:caroussel/carrousel.dart';
import 'package:caroussel/drawer.dart'; // Correction de l'importation du drawer
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:caroussel/utils.dart'; // Importation nécessaire pour requestNotificationPermission
import 'package:caroussel/root_app.dart';
import 'package:caroussel/guide.dart'; // Importation nécessaire pour OnBoardingPage
import 'package:caroussel/bottomNavbar.dart'; // Importation nécessaire pour BottomNavBar
import 'package:caroussel/pages/privacyPolicy.dart'; // Importation nécessaire pour PrivacyPolicy
import 'package:url_launcher/url_launcher.dart'; // Ajout pour utiliser launchUrl

// Importation nécessaire si Carrousel utilise File.file pour afficher les images

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisation des notifications locales
  await initNotifications();
  await requestNotificationPermission(); // gestion Android 13+

  // Verrouille l'orientation sur le mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Rendre la barre de navigation transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color.fromARGB(255, 236, 230, 230), // fond transparent
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark, // icônes blanches
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => DrawerSettingsProvider()),
      ],
      child: const RootApp(),
    ),
  );
}


class MyApp extends StatefulWidget {
  final bool showIntro;
  const MyApp({super.key, required this.showIntro});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isContainerVisible =
      false; // Contrôle la visibilité du widget Carrousel
  List<String>? _imagePath; // Contient les chemins des images sélectionnées
  // int? _autoScrollValue; // Valeur du défilement automatique (supprimé car inutilisé)
  bool swipeEnabled = false; // Contrôle si le swipe est activé
//  bool _showScrollHint = false; // Indique si l'astuce de défilement doit être affichée

  void activerSwipe() {
    setState(() {
      swipeEnabled = true; // Active le swipe
    });
  }

  Future<void> _checkFFmpegReady() async {
    log('Vérification si FFmpeg est prêt...');
    final session = await FFmpegKit.execute('-version');
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      log('FFmpeg est prêt.');
    } else {
      log('Erreur lors de la vérification de FFmpeg.');
    }
  }

  // Callback appelé par MediaUploader pour mettre à jour la visibilité du carrousel
  // et les chemins des images.
  void _imageContainer(List<String> imagePaths) {
    setState(() {
      _isContainerVisible = true;
      _imagePath = imagePaths;
    });
  }

  // Ce callback est potentiellement redondant si autoScrollValue est géré par le Provider
  // ou directement par le MediaUploader.
  void _selectedValue(int selectValue) {
    // Si cette méthode devait faire quelque chose, son implémentation irait ici.
  }

  // Callback appelé par MediaUploader pour mettre à jour la valeur de défilement automatique.
  // void autoScrollValue(int autoScrollValue) {
  //   setState(() {
  //     _autoScrollValue = autoScrollValue;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _checkFFmpegReady(); // Vérifie si FFmpeg est prêt au démarrage de l'application
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements dans CarouselProvider pour obtenir le nombre d'images.
    final carouselProvider = context.watch<CarouselProvider>();
    final int imageCount =
        carouselProvider.imageCount; // Récupère le nombre d'images

    return MaterialApp(
      // navigatorKey: navigatorKey, // Utilise la clé de navigation globale
      scaffoldMessengerKey: rootScaffoldMessengerKey, // Clé pour afficher les SnackBars
      home: Scaffold(
        endDrawerEnableOpenDragGesture: swipeEnabled,
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.from(alpha: 1, red: 0, green: 0.592, blue: 0.655),
          centerTitle: true, // L'AppBar s'occupe du centrage du titre
          titleSpacing:
              0, // Réduit l'espace entre l'icône de gauche et le titre
          leading: IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            tooltip: "Réinitialiser le carrousel",
            onPressed: () {
              carouselProvider.reset();
            },
            // Le padding a été ajusté ici
            padding: const EdgeInsets.only(left: 40.0),
          ),
          leadingWidth: 80.0,
          title: const Text(
            'Mon Carrousel',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 40.0),
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                tooltip: "Revoir le guide",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnBoardingPage(
                        onDone: () => Navigator.pop(context),
                        onSkip: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // Le tiroir de fin de Scaffold, qui contient les paramètres.
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width *
              0.8, // Le tiroir occupe 80% de la largeur de l'écran
          child: MyDrawer(
              scaffoldKey:
                  _scaffoldKey), // Passe la clé du Scaffold au MyDrawer
        ),
        //endDrawerEnableOpenDragGesture  est true par défaut, permettant l'ouverture par glissement.
        body: Column(
          mainAxisAlignment: MainAxisAlignment
              .center, // Centre verticalement le contenu principal
          children: [
            // ElevatedButton(onPressed: showVideoSavedNotification, child: const Text('Afficher la notification')),
            const SizedBox(height: 30.0), // Espace en haut de la colonne
            Carrousel(
                // Si Carrousel a besoin de la liste d'images, passez-lui directement du Provider:
                // images: carouselProvider.images,
                // Si Carrousel a besoin de la valeur de défilement du Provider:
                // autoScrollValue: carouselProvider.autoScrollValue,
                // Pour l'instant, on utilise la variable d'état locale de MyApp
                //autoScrollValue: _autoScrollValue,
                ),
            const SizedBox(
                height: 5), // Espace entre le carrousel et le compteur d'
            if (carouselProvider.isContainerVisible &&
                carouselProvider.images.isNotEmpty)
              Text(
                'Nombre d\'images sélectionnées : $imageCount',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          // Espace entre le carrousel et le conteneur MediaUploader
            // Le conteneur "Ajouter un Média" (MediaUploader)
            const SizedBox(height: 7.63), // Espace avant le conteneur MediaUploader
            Expanded(
              // Permet au conteneur de prendre l'espace restant dans la colonne
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8, // Limite la largeur du conteneur
                    maxHeight: MediaQuery.of(context).size.height * 0.9, // Limite la hauteur du conteneur
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(249, 250, 251, 1.0),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 10,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: IntrinsicHeight( // Ajuste la hauteur du Column à son contenu
 child: SingleChildScrollView( // Permet le défilement si le contenu dépasse la hauteur du Container parent
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Centre le contenu verticalement dans la zone visible si ça rentre
                      mainAxisSize: MainAxisSize.min, // <--- AJOUT CRUCIAL : La colonne prend juste la hauteur nécessaire
                      children: [
                        const Text(
                          'Ajouter un Média',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16), // Ajout d'un petit espace pour l'esthétique
                        MediaUploader(
                          scaffoldKey: _scaffoldKey,
                          imageContainerCallback: _imageContainer,
                          selectValueCallback: _selectedValue,
                          //autoScrollValueCallback: autoScrollValue,
                          onValidation: activerSwipe, // Callback pour activer le swipe
                        ),
                      ],
                    ),
                  ),
                  ),
                ),

              ),
            ),
            const SizedBox(
                height: 20), // Espace après le conteneur MediaUploader

            // Affichage conditionnel du Carrousel et du compteur d'images
            if (_isContainerVisible &&
                _imagePath != null &&
                _imagePath!.isNotEmpty) ...[
              // Le widget Carrousel (assumé qu'il prend ses images du Provider ou utilise _imagePath)

              const SizedBox(
                  height: 20), // Espace entre le carrousel et le compteur
            ],

            // --- AFFICHAGE DU COMPTEUR D'IMAGES SÉLECTIONNÉES ---
            // Ce texte est maintenant toujours affiché, indépendamment de la présence d'images.
            // Il sera à 0 si aucune image n'est sélectionnée.

            // --- FIN AFFICHAGE ---
            const SizedBox(height: 20), // Espace en bas de la colonne
          ],
        ),
        bottomNavigationBar: Container(
          // Hauteur du BottomNavBar
         // color: Colors.cyan[700], // Couleur de fond du BottomNavBar
          child: BottomNavBar(
            onPrivacyTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            }, // Callback pour ouvrir la page de politique de confidentialité
              onContactTap: () async {
                final String email = dotenv.env['mail'] ?? '';
                final Uri mailtoUri = Uri(
                  scheme: 'mailto',
                  path: email,
                  queryParameters: {
                    'subject': "Question concernant l'application Mon Carrousel",
                    'body':
                        "Bonjour,j'ai une question au sujet de l'application Mon Carrousel :",
                  },
                );

                if (await canLaunchUrl(mailtoUri)) {
                  await launchUrl(mailtoUri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Impossible d’ouvrir l’application mail.')),
                    );
                  }
                }
              }
          ),
        ),
      ),
    );
  }
}
