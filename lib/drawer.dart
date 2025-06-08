import 'package:caroussel/test_api.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:caroussel/option_modal.dart';
import 'carousel_provider.dart';
import 'package:provider/provider.dart';
import 'package:caroussel/media_uploader.dart';
import 'dart:developer';

class MyDrawer extends StatefulWidget {
  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? _audioFileName;
  String? _audioFilePath;
  String? _selectedMusic;
  bool _isDropdownDisabled = false;
  bool _isFilePickerDisabled = false;
  List _data = []; // Données de l’API
  String? audioSourcePath;

  @override
  void initState() {
    super.initState();
    fetchMusique();
  }

  void fetchMusique() async {
    try {
      var fetchedData = await fetchData();
      setState(() {
        _data = fetchedData;
      });
      print('Données récupérées: $_data');
    } catch (e) {
      print('Erreur de récupération des données: $e');
    }
  }

void _pickAudioFile() async {
  if (_isFilePickerDisabled) return;

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'wav'],
    allowMultiple: false,
  );

  if (result != null) {
    setState(() {
      _audioFilePath = result.files.single.path; // ✅ Le chemin complet
      _audioFileName = result.files.single.name;
      _selectedMusic = null;
      _isDropdownDisabled = true;
      _isFilePickerDisabled = false;
    });
    log("Fichier local sélectionné : $_audioFilePath"); // pour debug
  }
}


  @override
  Widget build(BuildContext context) {
    List<String> selectedImages = context.watch<CarouselProvider>().images;

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
              title: Text(
                "Parcourir un fichier audio",
                style: TextStyle(
                  color: _isFilePickerDisabled ? Colors.grey : Colors.black,
                ),
              ),
              enabled: !_isFilePickerDisabled,
              onTap: _isFilePickerDisabled ? null : _pickAudioFile,
            ),
          ),
          if (_audioFileName != null)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Fichier sélectionné : $_audioFileName",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: DropdownButtonFormField<String>(
              value: _selectedMusic,
              dropdownColor: Colors.white,
              hint: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Choisissez un son proposé',
                    style: TextStyle(color: Colors.black,fontSize:15.5),
                  ),
                ],
              ),
              decoration: const InputDecoration(
                labelText: 'Choisissez un son proposé',
                border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
              ),
              items: _data.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item['name'],
                  child: Text(item['name']),
                );
              }).toList(),
              onChanged: _isDropdownDisabled
                  ? null
                  : (value) {
                      setState(() {
                        _selectedMusic = value;
                        _audioFileName = null;
                        _isFilePickerDisabled = true;
                        _isDropdownDisabled = false;
                      });
                      log("Musique sélectionnée depuis l'API: $_selectedMusic");
                    },
              selectedItemBuilder: (BuildContext context) {
                return _data.map<Widget>((item) {
                  String text = item['name'].length > 20
                      ? '${item['name'].substring(0, 20)}...'
                      : item['name'];
                  return Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
            ),
          ),



                Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _audioFileName = null;
              _selectedMusic = null;
              _isDropdownDisabled = false;
              _isFilePickerDisabled = false;
            });
          },
          icon: Icon(Icons.restart_alt),
          label: Text("J’annule mon choix"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ),
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
// onPressed: () async {
//   if (!context.mounted) return;
//   final parentContext = context;

//   Navigator.pop(parentContext); // ferme le drawer si ouvert

//   // Affiche le loader
//   showDialog(
//     context: parentContext,
//     barrierDismissible: false,
//     builder: (_) => const Center(child: CircularProgressIndicator()),
//   );

//   try {
//     final videoPath = await convertImagesToVideo(selectedImages);

//     if (!parentContext.mounted) return;

//     Navigator.pop(parentContext); // ferme le loader

//     if (videoPath != null && videoPath.isNotEmpty) {
//       // Affiche ta modal personnalisée
//       optionModal(parentContext, videoPath);
//     } else {
//       ScaffoldMessenger.of(parentContext).showSnackBar(
//         const SnackBar(content: Text("Erreur dans la génération de la vidéo")),
//       );
//     }
//   } catch (e, s) {
//     if (!parentContext.mounted) return;
//     Navigator.pop(parentContext); // ferme le loader
//     ScaffoldMessenger.of(parentContext).showSnackBar(
//       const SnackBar(content: Text("Une erreur est survenue")),
//     );
//     log('❌ Exception pendant la génération de la vidéo : $e\n$s');
//   }
// }
onPressed: () async {
  final stableContext = Navigator.of(context, rootNavigator: true).context;

  Navigator.pop(context); // Fermer le drawer

  showDialog(
    context: stableContext,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String? audioSourceForVideo; // Variable pour la source audio finale

  // --- LOGIQUE CORRIGÉE POUR PRÉPARER LA SOURCE AUDIO ---
  if (_audioFilePath != null) {
    // L'utilisateur a choisi un fichier local
    audioSourceForVideo = _audioFilePath;
    log('Source audio: Fichier local sélectionné: $audioSourceForVideo');
  } else if (_selectedMusic != null) {
    // L'utilisateur a choisi un son de l'API
    final selectedItem = _data.firstWhere(
      (item) => item['name'] == _selectedMusic,
      orElse: () => null,
    );
    if (selectedItem != null) {
      final int soundId = selectedItem['id']; // Récupérez l'ID du son
      log('Source audio: Son API sélectionné (ID: $soundId). Récupération de l\'URL via getSoundDownloadUrl...');

      // <<< C'EST ICI LE CHANGEMENT CLÉ ! >>>
      // On appelle getSoundDownloadUrl pour obtenir l'URL correcte de l'API
      audioSourceForVideo = await getSoundDownloadUrl(soundId);

      if (audioSourceForVideo == null) {
        log('❌ Échec de la récupération de l\'URL audio depuis l\'API pour ID: $soundId');
        // Gérer l'erreur, informer l'utilisateur, etc.
        Navigator.of(stableContext, rootNavigator: true).pop(); // Fermer le spinner
        ScaffoldMessenger.of(stableContext).showSnackBar(
          const SnackBar(content: Text("Erreur: Impossible de charger le son de l'API")),
        );
        return; // Arrêter la fonction
      }
      log('Source audio: URL API récupérée: $audioSourceForVideo');
    } else {
      log('⚠️ Aucun élément sélectionné correspondant dans _data.');
    }
  } else {
    // Aucun son sélectionné (ni local, ni API)
    log('⚠️ Aucune source audio sélectionnée. La vidéo sera générée sans audio.');
    // audioSourceForVideo reste null, ce qui est géré par convertImagesToVideo
  }
  // ----------------------------------------------------------------------

  // Appeler convertImagesToVideo avec la source audio préparée
  String videoUrl = await convertImagesToVideo(
    selectedImages,
    audioSource: audioSourceForVideo, // Passe la bonne source !
  );

  // Simule une attente (vous pouvez enlever ça si ce n'est pas un vrai délai)
  await Future.delayed(Duration(seconds: 3));

  // Fermer le spinner
  Navigator.of(stableContext, rootNavigator: true).pop();

  // Ouvrir la modal vidéo
  if (videoUrl.isNotEmpty) {
    optionModal(stableContext, videoUrl);
  } else {
    ScaffoldMessenger.of(stableContext).showSnackBar(
      const SnackBar(content: Text("Erreur dans la génération de la vidéo")),
    );
  }
},

              child: Text('Créer La Vidéo',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
