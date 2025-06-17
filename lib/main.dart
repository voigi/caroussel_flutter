import 'package:flutter/material.dart';
import 'package:caroussel/media_uploader.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';
import 'package:caroussel/carrousel.dart';
import 'package:caroussel/drawer.dart'; // Correction de l'importation du drawer
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
// Importation nécessaire si Carrousel utilise File.file pour afficher les images

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Verrouille l'orientation sur le mode portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Mode portrait vertical
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CarouselProvider()),
        ],
        child: const MyApp(),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isContainerVisible = false; // Contrôle la visibilité du widget Carrousel
  List<String>? _imagePath; // Contient les chemins des images sélectionnées
  int? _autoScrollValue; // Valeur du défilement automatique

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
  void autoScrollValue(int autoScrollValue) {
    setState(() {
      _autoScrollValue = autoScrollValue;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkFFmpegReady(); // Vérifie si FFmpeg est prêt au démarrage de l'application
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements dans CarouselProvider pour obtenir le nombre d'images.
    final carouselProvider = context.watch<CarouselProvider>();
    final int imageCount = carouselProvider.imageCount; // Récupère le nombre d'images

    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.cyan[700],
          title: const Center(child: Text('Mon Carrousel', style: TextStyle(color: Colors.white))),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.settings, color: Colors.white),
            //   onPressed: () {
            //     _scaffoldKey.currentState?.openEndDrawer(); // Ouvre le tiroir
            //   },
            // ),
            // Bouton invisible pour maintenir l'alignement à droite de l'AppBar.
            const IconButton(onPressed: null, icon: Icon(Icons.search, color: Colors.transparent)),
          ],
        ),
        // Le tiroir de fin de Scaffold, qui contient les paramètres.
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // Le tiroir occupe 80% de la largeur de l'écran
          child: MyDrawer(scaffoldKey: _scaffoldKey), // Passe la clé du Scaffold au MyDrawer
        ),
        // `endDrawerEnableOpenDragGesture` est true par défaut, permettant l'ouverture par glissement.
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement le contenu principal
          children: [
            const SizedBox(height: 30.0), // Espace en haut de la colonne
                          Carrousel(
                // Si Carrousel a besoin de la liste d'images, passez-lui directement du Provider:
                // images: carouselProvider.images,
                // Si Carrousel a besoin de la valeur de défilement du Provider:
                // autoScrollValue: carouselProvider.autoScrollValue,
                // Pour l'instant, on utilise la variable d'état locale de MyApp
                autoScrollValue: _autoScrollValue,
              ),
              if(_isContainerVisible && _imagePath != null && _imagePath!.isNotEmpty)
                 Text(
              'Nombre d\'images sélectionnées : $imageCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            
               
            // Le conteneur "Ajouter un Média" (MediaUploader)
            Expanded( // Permet au conteneur de prendre l'espace restant dans la colonne
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Centre le contenu du Column interne
                      children: [
                        const Text(
                          'Ajouter un Média',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        MediaUploader(
                          scaffoldKey: _scaffoldKey,
                         // imagePath: const [], // Ce paramètre est maintenant géré principalement par le Provider
                          imageContainerCallback: _imageContainer, // Callback pour gérer la visibilité du carrousel
                          selectValueCallback: _selectedValue, // Callback de MediaUploader (si utilisé)
                          autoScrollValueCallback: autoScrollValue, // Callback pour le défilement automatique
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Espace après le conteneur MediaUploader

            // Affichage conditionnel du Carrousel et du compteur d'images
            if (_isContainerVisible && _imagePath != null && _imagePath!.isNotEmpty) ...[
              // Le widget Carrousel (assumé qu'il prend ses images du Provider ou utilise _imagePath)

              const SizedBox(height: 20), // Espace entre le carrousel et le compteur
            ],

            // --- AFFICHAGE DU COMPTEUR D'IMAGES SÉLECTIONNÉES ---
            // Ce texte est maintenant toujours affiché, indépendamment de la présence d'images.
            // Il sera à 0 si aucune image n'est sélectionnée.
          
            // --- FIN AFFICHAGE ---
            const SizedBox(height: 20), // Espace en bas de la colonne
          ],
        ),
      ),
    );
  }
}