import 'package:caroussel/upload_file.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:provider/provider.dart';
import 'carousel_provider.dart';
//import 'package:file_picker/file_picker.dart';


Future<void> editModal(BuildContext context,Function(String) updateImage, int index) {





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
                  String? newPath = await pickFile();
                  if(!context.mounted) return;
                if (newPath != null) {
                 log('🖼 Mise à jour de l\'image à l\'index $index avec $newPath');
                  context.read<CarouselProvider>().updateImageAtIndex(index, newPath);
                  
                }else{
                  log('❌ Aucun fichier sélectionné');
                }
                Navigator.of(context).pop(); // Ferme la modal
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
