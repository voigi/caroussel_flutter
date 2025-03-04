import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
//import 'dart:developer';
import 'package:caroussel/option_modal.dart';
import 'package:caroussel/test_api.dart';

class MyDrawer extends StatefulWidget {
  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? _audioFileName;
  List _data = [];
  String? _selectedMusic; 

  @override
  void initState() {
    super.initState();
    fetchMusique();
  }

  // Fonction pour récupérer les données de l'API et les mettre à jour dans _data
  void fetchMusique() async {
    try {
      var fetchedData = await fetchData(); // Appel de ta fonction fetchData
      setState(() {
        _data =
            fetchedData; // Mise à jour de la liste avec les données récupérées
      });
      print('Données récupérées: $_data');
    } catch (e) {
      // Si erreur, tu peux afficher un message d'erreur
      print('Erreur de récupération des données: $e');
    }
  }

  void _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        // Récupérer le chemin du fichier audio
        _audioFileName = result.files.single.name;
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
            padding: const EdgeInsets.only(left: 20.0),
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
                )),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: DropdownButtonFormField(
              dropdownColor: Colors.white,
              hint: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.blue),
                  Text(
                    'Selectionnez une musique',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              decoration: const InputDecoration(
                labelText: 'Selectionnez une musique',
                border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
              ),
              items: _data.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value:
                      item['name'], // Stocke le nom de la musique comme valeur
                  child: Text(
                    item['name'],
                   
                  ), // Affiche le nom de la musique
                );
              }).toList(),
              onChanged: (value) {
               setState(() {
                 _selectedMusic = value;
               });
              },
                      selectedItemBuilder: (BuildContext context) {
          return _data.map<Widget>((item) {
            String text = item['name'].length > 20 
                ? '${item['name'].substring(0, 20)}...' 
                : item['name']; 

            return Text(
              text,
              overflow: TextOverflow.ellipsis, // Tronque uniquement la sélection affichée
            );
          }).toList();
        },
            ),
          ),

          //  SizedBox(
          //   height: 200,
          //    child: ListView.builder
          //    (
          //     itemCount: _data.length,
          //     itemBuilder:(context, index) {
          //     return ListTile(
          //     title: Text(_data[index]['name'])
          //     );

          //    }

          //    )
          //    ,
          //  ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
              child: Text('Valider',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
