import 'package:caroussel/upload_file.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

Future<void> editModal(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
              child: Text(
            'Remplacement de l\'image',
            style: TextStyle(fontSize: 22),
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voulez-vous remplacer votre image ?',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await pickFile();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                ),
                icon: Icon(Icons.upload_file, color: Colors.white),
                label: Text(
                  'Choisir un fichier'.toUpperCase(),
                  /*  */
                  style: TextStyle(color: Colors.white),
                ),
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
