import 'package:flutter/material.dart';
import 'dart:developer';



Future <void> optionModal(BuildContext context) {
    return showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Aperçu de  votre vidéo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous vraiment valider ces options ?', style: TextStyle(fontSize: 13)),
            SizedBox(height: 20),
            Placeholder(
              fallbackHeight: 200,
              fallbackWidth: 200,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              log('Options annulées');
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              log('Options validées');
            },
            child: Text('Valider'),
          ),
        ],
      );
    });
   
   
  }

