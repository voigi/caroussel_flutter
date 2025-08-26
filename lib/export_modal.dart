import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';

// --- MODAL SIMPLIFIÉE ---
// Affiche une modale de choix claire et directe après l'enregistrement de la vidéo.
// Conçue pour un public peu familier avec la navigation mobile, cette approche
// évite les étapes multiples et offre des actions explicites.

void ExportDialog(BuildContext context) {
  final carouselProvider = Provider.of<CarouselProvider>(context, listen: false);

  showDialog(
    context: context,
    // L'utilisateur doit faire un choix explicite, il ne peut pas fermer la modale accidentellement.
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Vidéo enregistrée !', textAlign: TextAlign.center),
        content: const Text('Que souhaitez-vous faire maintenant ?', textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          // Utilisation d'une colonne pour que les boutons soient larges et faciles à cliquer.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer une nouvelle vidéo'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // 1. Réinitialise l'état de l'application pour une nouvelle création.
                  carouselProvider.reset();
                  // 2. Ferme cette modale, ramenant l'utilisateur à l'écran de création.
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Quitter'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // Ferme l'application proprement. C'est la méthode recommandée
                  // pour un bouton de sortie explicite.
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}