import 'dart:async';
import 'dart:io';
import 'dart:developer'; // Pour les logs de débogage
import 'package:caroussel/carousel_provider.dart'; // Assurez-vous d'avoir le chemin correct
import 'package:flutter/material.dart';
import 'package:caroussel/edit_modal.dart'; // Assurez-vous d'avoir le chemin correct
import 'package:provider/provider.dart';

class Carrousel extends StatefulWidget {
  // Le widget Carrousel n'a plus besoin de paramètres pour l'état interne,
  // car il lira toutes les informations nécessaires directement depuis le CarouselProvider.
  const Carrousel({super.key});

  @override
  State<Carrousel> createState() => _CarrouselState();
}

class _CarrouselState extends State<Carrousel> {
  int currentIndex = 0; // Index de l'image actuellement affichée dans le carrousel
  Timer? _timer; // Timer pour le défilement automatique

  // Ce listener sera appelé chaque fois que notifyListeners() est déclenché dans CarouselProvider.
  // C'est le cœur de la réactivité du carrousel aux changements de son état.
  VoidCallback? _providerListener;

  @override
  void initState() {
    super.initState();

    // 1. Définition du listener pour le CarouselProvider.
    _providerListener = () {
      final carouselProvider = context.read<CarouselProvider>();
      final newAutoScrollValue = carouselProvider.autoScrollValue;
      final currentImageCount = carouselProvider.images.length;

      // Gère le démarrage ou l'arrêt du timer de défilement automatique
      _setAutoScrollTimer(newAutoScrollValue);

      // S'assure que l'index actuel reste valide après une modification des images (ajout/suppression).
      if (currentIndex >= currentImageCount && currentImageCount > 0) {
        // Si l'index dépasse la taille de la liste, on le ramène à la dernière image.
        setState(() {
          currentIndex = currentImageCount - 1;
        });
      } else if (currentImageCount == 0 && currentIndex != 0) {
        // Si la liste devient vide, on réinitialise l'index à 0.
        setState(() {
          currentIndex = 0;
        });
      }
    };

    // 2. Ajout du listener au CarouselProvider.
    // context.read est utilisé car on ne veut pas déclencher une reconstruction du widget juste pour s'abonner.
    context.read<CarouselProvider>().addListener(_providerListener!);

    // 3. Initialisation du timer au démarrage du widget, basée sur la valeur initiale du provider.
    _setAutoScrollTimer(context.read<CarouselProvider>().autoScrollValue);
  }

  /// Gère le démarrage ou l'arrêt du timer de défilement automatique.
  /// Cette méthode est appelée par le listener du Provider lorsque `autoScrollValue` change.
  void _setAutoScrollTimer(int? autoScrollValue) {
    // Annule tout timer existant pour éviter les timers multiples ou obsolètes.
    _timer?.cancel();
    _timer = null; // S'assure que la référence est nulle après annulation.

    if (autoScrollValue == 1) {
      log('✅ _setAutoScrollTimer: Défilement automatique activé. Démarrage du timer.');
      // Démarre un nouveau timer qui se déclenche toutes les 2 secondes.
      _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
        log('⏱️ Timer Tick: Appel de nextIndex().');
        nextIndex(); // Passe à l'image suivante.
      });
    } else {
      log('❌ _setAutoScrollTimer: Défilement automatique désactivé ou valeur non reconnue ($autoScrollValue). Arrêt du timer.');
    }
  }

  /// Met à jour l'image à l'index courant dans le CarouselProvider.
  /// Cette fonction est passée au modal d'édition.
  void updateImageAtIndex(String newPath) {
    // Demande au Provider de mettre à jour l'image. Le Provider notifiera les écouteurs.
    context.read<CarouselProvider>().updateImageAtIndex(currentIndex, newPath);
  }

  /// Passe à l'image suivante dans le carrousel.
  void nextIndex() {
    final imagePaths = context.read<CarouselProvider>().images;
    if (imagePaths.isNotEmpty) {
      // Calcul du nouvel index en s'assurant de revenir au début si on atteint la fin.
      int newIndex = (currentIndex + 1) % imagePaths.length;
      log('➡️ nextIndex: Changement d\'index de $currentIndex à $newIndex. Images disponibles: ${imagePaths.length}');
      setState(() {
        currentIndex = newIndex; // Met à jour l'index et déclenche une reconstruction.
      });
    } else {
      log('⚠️ nextIndex: Aucune image dans le carrousel, impossible de défiler.');
      setState(() {
        currentIndex = 0; // S'il n'y a pas d'images, l'index reste 0.
      });
    }
  }

  /// Passe à l'image précédente dans le carrousel.
  void previousIndex() {
    final imagePaths = context.read<CarouselProvider>().images;
    if (imagePaths.isNotEmpty) {
      // Calcul du nouvel index en s'assurant de revenir à la fin si on est au début.
      int newIndex = (currentIndex - 1 + imagePaths.length) % imagePaths.length;
      setState(() {
        currentIndex = newIndex; // Met à jour l'index et déclenche une reconstruction.
      });
    } else {
      setState(() {
        currentIndex = 0; // S'il n'y a pas d'images, l'index reste 0.
      });
    }
  }

  /// Supprime l'image actuellement affichée du carrousel.
  void deleteImage() {
    final carouselProvider = context.read<CarouselProvider>();
    final imagePaths = carouselProvider.images;

    if (imagePaths.isNotEmpty && currentIndex >= 0 && currentIndex < imagePaths.length) {
      setState(() {
        // Demande au Provider de supprimer l'image à l'index courant.
        // Le `_providerListener` se chargera d'ajuster `currentIndex` si nécessaire après cette suppression.
        carouselProvider.removeImage(currentIndex);
      });
    }
  }

  @override
  void dispose() {
    // Très important : Annule le timer pour éviter les exécutions en arrière-plan.
    _timer?.cancel();
    // Très important : Retire le listener du Provider pour éviter les fuites de mémoire.
    context.read<CarouselProvider>().removeListener(_providerListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // context.watch rend ce widget réactif aux changements dans CarouselProvider.
    // Chaque fois que notifyListeners() est appelé dans le Provider, build est ré-exécuté.
    final carouselProvider = context.watch<CarouselProvider>();
    final imagePaths = carouselProvider.images; // La liste des chemins d'images
    final int? autoScrollValue = carouselProvider.autoScrollValue; // La valeur du défilement automatique

    log('Carrousel Build - Valeur défilement auto (Provider): $autoScrollValue');
    log('Carrousel Build - Images (Provider): ${imagePaths.length} images');
    log('Carrousel Build - Index actuel: $currentIndex');

    // Message à afficher si aucune image n'est disponible.
    if (imagePaths.isEmpty) {
      // S'assure que l'index courant est 0 si la liste est vide.
      if (currentIndex != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => currentIndex = 0);
        });
      }
      return const Center(child: Text("Ajoutez des images pour démarrer le carrousel."));
    }

    // Gestion de sécurité pour l'index si la liste change de taille (ex: suppression).
    // Si l'index courant n'est plus valide, on le ramène à la dernière image valide.
    if (currentIndex >= imagePaths.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => currentIndex = imagePaths.length - 1);
      });
      // Retourne un widget vide temporaire pour éviter une erreur "index out of range"
      // pendant que l'index est ajusté et que le widget se reconstruit.
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.3,
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.file(
                // Affiche l'image correspondant à l'index courant.
                File(imagePaths[currentIndex]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Conditionne l'affichage et l'interactivité des boutons
          // en fonction de l'état du défilement automatique.
          if (autoScrollValue == 1) ...[
            // Si le défilement automatique est activé, les boutons sont visuellement absents/inactifs.
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () {}, // Pas d'action visible ou active
                icon: const Icon(Icons.edit, size: 35.0),
                color: Colors.transparent, // Rend l'icône invisible
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: () {}, // Pas d'action visible ou active
                icon: const Icon(Icons.delete, size: 35.0),
                color: Colors.transparent, // Rend l'icône invisible
              ),
            ),
          ] else ...[
            // Si le défilement automatique est désactivé (valeur 0 ou null), les boutons sont actifs.
            Positioned(
              right: 2,
              child: IconButton(
                onPressed: () async {
                  await editModal(context, updateImageAtIndex, currentIndex);
                },
                icon: const Icon(Icons.edit, size: 35.0),
              ),
            ),
            Positioned(
              child: IconButton(
                onPressed: deleteImage,
                icon: const Icon(Icons.delete, size: 35.0),
                color: Colors.red,
              ),
            ),
            Positioned(
              right: 5.0,
              top: 93.0,
              child: IconButton(
                onPressed: nextIndex,
                icon: const Icon(
                  Icons.arrow_circle_right_outlined,
                  size: 35.0,
                ),
              ),
            ),
            Positioned(
              left: 5.0,
              top: 93.0,
              child: IconButton(
                onPressed: previousIndex,
                icon: const Icon(
                  Icons.arrow_circle_left_outlined,
                  size: 35.0,
                ),
              ),
            )
          ],
        ],
      ),
    );
  }
}