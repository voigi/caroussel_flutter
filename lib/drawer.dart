

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';
import 'package:caroussel/option_modal.dart';

class MyDrawer extends StatefulWidget {
  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {

  String? _audioFileName;

  void _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        // Récupérer le chemin du fichier audio
      _audioFileName= result.files.single.name;
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
        DrawerHeader(
  decoration: BoxDecoration(
    color: Colors.cyan[700],
  
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Paramètres',
        style: TextStyle(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Personnalisez votre expérience et ajustez vos préférences ici.',
        style: TextStyle(
          color: Colors.white70, 
          fontSize: 14,
        ),
      ),
    ],
  ),
),
         
       
          Padding(
            padding: const EdgeInsets.only(left:20.0),
            child: ListTile(
              leading: Icon(Icons.music_note),
              title: Text("Parcourir un fichier audio"),
              onTap: _pickAudioFile,
            ),
          ),
          if (_audioFileName != null)
             Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Fichier sélectionné : $_audioFileName",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              )
             )
              ,
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
         child:DropdownButtonFormField(
               dropdownColor: Colors.white,
            hint: Row(
              children: [
                Icon(Icons.music_note, color: Colors.blue),
                Text('Selectionnez une musique',
                style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            decoration: const InputDecoration(
             labelText: 'Selectionnez une musique',
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
            ),
          items:  const [
              DropdownMenuItem(
                value: 1,
                child: Text('Oui'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text('Non'),
              ),
            ], onChanged: (value) {},),
            //button qui valide les options
            
          ),
           //button qui valide les options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: ElevatedButton(
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan[700],
             
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
             ),
              onPressed: () {
                // Fermer le drawer
                Navigator.pop(context);
                optionModal(context);

              },
              child: Text('Valider', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),)
        ],
      ),
    );
  }
}
