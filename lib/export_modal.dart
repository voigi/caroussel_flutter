import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:flutter/services.dart'; 
import 'carousel_provider.dart';


// Fonction pour afficher une modal qui demande si l'utilisateur veut faire une autre vidéo ou non, si non ,on remercie l'utilisateur et ferme l'application

void ExportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(child: Text('Vidéo Enregistrée!')),
        content: Text('Voulez-vous créer une autre vidéo?'),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green, // Couleur de fond bleue
              foregroundColor: Colors.white, // Couleur du texte blanche
            ),
            child: Text('Oui'),
            onPressed: () {
              // Réinitialiser l'état de l'application pour permettre la création d'une nouvelle vidéo
              final carouselProvider = Provider.of<CarouselProvider>(context, listen: false); carouselProvider.reset();
              Navigator.of(context).pop(); // Fermer la modal
            },
          ),
          SizedBox(width: 20), // Espacement entre les boutons
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red, // Couleur de fond rouge
              foregroundColor: Colors.white, // Couleur du texte blanche
            ),
            child: Text('Non'),
            onPressed: () {
              // Remercier l'utilisateur et fermer l'application
              Navigator.of(context).pop(); // Fermer la modal
              showDialog(
                context: context,
                barrierDismissible: false, // empecher de fermer la modale en cliquant en dehors
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Center(child: Text('Merci!')),
                    content: Text('Merci d\'avoir utilisé notre application!'),
                    actions: <Widget>[
                      Center(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red, // Couleur de fond rouge
                            foregroundColor: Colors.white, // Couleur du texte blanche
                          ),
                          child: Text('Fermer l\'application'),
                          onPressed: () {
                            SystemNavigator.pop(); // Fermer l'application
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
          ),
        ],
      );
    },
  );
}



