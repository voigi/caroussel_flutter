// Fichier : my_drawer.dart

import 'package:caroussel/notif.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:caroussel/option_modal.dart';
import 'carousel_provider.dart';
import 'package:provider/provider.dart';
import 'package:caroussel/media_uploader.dart'; // Assurez-vous que convertImagesToVideo est bien là
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:caroussel/test_api.dart'; // Assurez-vous que fetchData et getSoundDownloadUrl sont là

// Assurez-vous que cette fonction est bien importée ou définie globalement si elle est utilisée ici
// Si elle est dans media_uploader.dart, assurez-vous de l'importer correctement
// import 'package:caroussel/media_uploader.dart'; // Importez le fichier qui contient convertImagesToVideo

class MyDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const MyDrawer({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? _audioFileName;
  String? _audioFilePath;
  String? _selectedMusic;
  bool _isDropdownDisabled = false;
  bool _isFilePickerDisabled = false;
  List _data = [];

  final TextEditingController _searchController = TextEditingController(text: 'background');
  String _searchKeyword = 'background';

  final List<String> _suggestedKeywords = [
    'Ambiance',
    'Nature',
    'Effet',
  ];

  // --- NOUVEAU : GlobalKey pour le formulaire du titre ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  // --- NOUVEAU : Variable pour suivre l'état de validation du titre ---
  bool _isTitleValid = false; // Initialisé à false, car le champ est vide au démarrage

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool _isAudioOptionsExpanded = false;

  @override
  void initState() {
    super.initState();
    _performApiSearch();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    // --- NOUVEAU : Écouter les changements dans le contrôleur de titre ---
    _titleController.addListener(_validateTitleOnChanged);
    // Valider une première fois au démarrage si le champ a une valeur initiale
    _validateTitleOnChanged(); // Pour initialiser _isTitleValid
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    // --- NOUVEAU : Retirer le listener et disposer du contrôleur de titre ---
    _titleController.removeListener(_validateTitleOnChanged);
    _titleController.dispose();
    super.dispose();
  }

  // --- NOUVELLE FONCTION : Valider le titre à chaque changement ---
  void _validateTitleOnChanged() {
    setState(() {
      _isTitleValid = _titleController.text.trim().isNotEmpty;
    });
  }

  void _performApiSearch() async {
    _stopAudio();
    _selectedMusic = null;
    _isDropdownDisabled = false;
    _isFilePickerDisabled = false;

    setState(() {
      _searchKeyword = _searchController.text.trim().isEmpty ? 'background' : _searchController.text.trim();
    });

    try {
      var fetchedData = await fetchData(keyword: _searchKeyword);
      setState(() {
        _data = fetchedData;
      });
      log('Données API récupérées avec succès pour le mot-clé "$_searchKeyword": $_data');
    } catch (e) {
      log('Erreur lors de la récupération des données API pour le mot-clé "$_searchKeyword": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la récupération des sons pour '$_searchKeyword'.")),
        );
      }
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
        _audioFilePath = result.files.single.path;
        _audioFileName = result.files.single.name;
        _selectedMusic = null;
        _isDropdownDisabled = true;
        _isFilePickerDisabled = false;
      });
      _stopAudio();
      log("Fichier local sélectionné : $_audioFilePath");
    }
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    if (_audioFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
      log('Lecture audio locale depuis : $_audioFilePath');
    } else if (_selectedMusic != null) {
      final Map<String, dynamic>? selectedItem = _data.firstWhereOrNull(
        (item) => item['name'] == _selectedMusic,
      );

      if (selectedItem != null) {
        final int soundId = selectedItem['id'];
        final String? soundUrl = await getSoundDownloadUrl(soundId);
        if (soundUrl != null) {
          await _audioPlayer.play(UrlSource(soundUrl));
          log('Lecture audio API depuis l\'URL : $soundUrl');
        } else {
          log('Échec de l\'obtention de l\'URL audio depuis l\'API pour ID: $soundId');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Impossible de lire le son de l'API")),
            );
          }
        }
      } else {
        log('Aucun élément correspondant trouvé pour la musique sélectionnée: $_selectedMusic');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Le son sélectionné n'est plus disponible")),
          );
        }
      }
    } else {
      log('Aucune source audio sélectionnée pour la lecture.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez sélectionner un son pour la lecture")),
        );
      }
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resetAudioChoices() {
    _stopAudio();
    setState(() {
      _audioFileName = null;
      _audioFilePath = null;
      _selectedMusic = null;
      _isDropdownDisabled = false;
      _isFilePickerDisabled = false;
      _searchController.text = 'background';
      _titleController.clear();
      _performApiSearch();
      _isTitleValid = false; // Réinitialiser la validation du titre
    });
  }

  Widget _buildAudioControlsSection() {
    String displayText;
    bool isAudioSelected = (_audioFileName != null || _selectedMusic != null);

    if (isAudioSelected) {
      displayText = "Son sélectionné : ";
    } else {
      displayText = "Aucun son sélectionné";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_down_rounded, color: isAudioSelected ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isAudioSelected ? Colors.black : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAudioSelected)
                Expanded(
                  child: Text(
                    _audioFileName ?? _selectedMusic!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAudioSelected ? Colors.black : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPlayStopButtons(isAudioSelected),
        ],
      ),
    );
  }

  Widget _buildPlayStopButtons(bool isAudioSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(_isPlaying ? 'Pause' : 'Play'),
            onPressed: isAudioSelected ? _playAudio : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAudioSelected ? Colors.blue[600] : Colors.grey[300],
              foregroundColor: isAudioSelected ? Colors.white : Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            onPressed: isAudioSelected ? _stopAudio : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAudioSelected ? Colors.red[600] : Colors.grey[300],
              foregroundColor: isAudioSelected ? Colors.white : Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> selectedImages = context.watch<CarouselProvider>().images;

    String selectedAudioSummaryText;
    bool isAudioSelectedForSummary = (_audioFileName != null || _selectedMusic != null);

    if (_audioFileName != null && _audioFilePath != null) {
      selectedAudioSummaryText = _audioFileName!;
    } else if (_selectedMusic != null) {
      selectedAudioSummaryText = _selectedMusic!;
    } else {
      selectedAudioSummaryText = 'Aucun son sélectionné';
    }

    // --- NOUVEAU : Condition d'activation du bouton "Créer l'Aperçu" ---
    // Le bouton est activé si:
    // - Il y a au moins 2 images sélectionnées
    // - Le champ de titre n'est pas vide (_isTitleValid est true)
    bool isCreatePreviewButtonEnabled = selectedImages.length >= 2 && _isTitleValid;


    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: 175,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.cyan[700],
              ),
              child: const Column(
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
          ),

          ExpansionTile(
            key: const PageStorageKey('audioOptions'),
            initiallyExpanded: _isAudioOptionsExpanded,
            onExpansionChanged: (bool expanded) {
              setState(() {
                _isAudioOptionsExpanded = expanded;
              });
            },
            title: const Text('Options Audio'),
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Icon(Icons.volume_up),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            controlAffinity: ListTileControlAffinity.trailing,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                child: ListTile(
                  leading: const Icon(Icons.folder_open),
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sons pour l\'API :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 1.0,
                      children: _suggestedKeywords.map((keyword) {
                        return ActionChip(
                          label: Text(
                            keyword,
                            style: const TextStyle(fontSize: 12),
                          ),
                          labelStyle: TextStyle(color: Colors.blue[800]),
                          backgroundColor: Colors.blue[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.blue.shade200),
                          ),
                          onPressed: () {
                            _searchController.text = keyword;
                            _performApiSearch();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedMusic,
                  dropdownColor: Colors.white,
                  hint: const Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Choisissez un son proposé',
                        style: TextStyle(color: Colors.black,fontSize:13.7),
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
                            _audioFilePath = null;
                            _isFilePickerDisabled = true;
                            _isDropdownDisabled = false;
                          });
                          _stopAudio();
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

              _buildAudioControlsSection(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: ElevatedButton.icon(
                  onPressed: _resetAudioChoices,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("J’annule mon choix"),
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
              const SizedBox(height: 10),
            ],
          ),

          // --- Section "Titre de la Vidéo" avec Form et TextFormField ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey, // --- ASSIGNEZ LA CLÉ DU FORMULAIRE ICI ---
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la vidéo', // Retire "(optionnel)" car il est obligatoire
                  hintText: 'Ex: "Mes vacances d\'été"',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _titleController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _titleController.clear();
                            _validateTitleOnChanged(); // Re-valide après effacement
                          },
                        )
                      : null,
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) { // Vérifie aussi les espaces blancs
                    return 'Le titre de la vidéo est obligatoire.'; // Message d'erreur
                  }
                  return null;
                },
                onChanged: (value) {
                  _validateTitleOnChanged(); // Met à jour l'état de validation du titre
                },
              ),
            ),
          ),
          const Divider(),

          // --- Section : Récapitulatif des options sélectionnées AVEC CONTRÔLES AUDIO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif des options :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Titre sélectionné : ${_titleController.text.isNotEmpty ? _titleController.text : 'Non défini'}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Son sélectionné : ',
                      style: TextStyle(fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        selectedAudioSummaryText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPlayStopButtons(isAudioSelectedForSummary),
              ],
            ),
          ),
          const Divider(),

          // --- Bouton "Créer L'Aperçu" (maintenant le bouton de soumission) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCreatePreviewButtonEnabled ? Colors.cyan[700] : Colors.grey, // Couleur dynamique
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              // --- Logique onPressed MODIFIÉE pour la validation ---
              onPressed: isCreatePreviewButtonEnabled // Désactiver si les conditions ne sont pas remplies
                  ? () async {
                      // Déclenche la validation de tous les TextFormField dans le Form associé à _formKey
                      if (_formKey.currentState!.validate()) {
                        // Si le formulaire est valide (titre non vide), procéder à la création
                        final stableContext = Navigator.of(context, rootNavigator: true).context;

                        widget.scaffoldKey.currentState?.closeEndDrawer();

                        showDialog(
                          context: stableContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        String? audioSourceForVideo;

                        if (_audioFilePath != null) {
                          audioSourceForVideo = _audioFilePath;
                          log('Source audio: Fichier local sélectionné: $audioSourceForVideo');
                        } else if (_selectedMusic != null) {
                          final Map<String, dynamic>? selectedItem = _data.firstWhereOrNull(
                            (item) => item['name'] == _selectedMusic,
                          );

                          if (selectedItem != null) {
                            final int soundId = selectedItem['id'];
                            audioSourceForVideo = await getSoundDownloadUrl(soundId);
                            log('Source audio: URL API récupérée: $audioSourceForVideo');
                          } else {
                            log('Aucun élément correspondant trouvé pour la musique sélectionnée dans _data pour la vidéo.');
                            if (mounted) {
                              ScaffoldMessenger.of(stableContext).showSnackBar(
                                const SnackBar(content: Text("Le son API sélectionné n'est plus disponible.")),
                              );
                              Navigator.of(stableContext, rootNavigator: true).pop();
                              return;
                            }
                          }
                        } else {
                          log('⚠️ Aucune source audio sélectionnée. La vidéo sera générée sans audio.');
                        }

                        // Le titre est maintenant garanti d'être non-null et non-vide grâce à la validation
                        final String videoTitle = _titleController.text.trim();
                        log('Titre de la vidéo : $videoTitle');

                        String videoUrl = await convertImagesToVideo(
                          selectedImages,
                          audioSource: audioSourceForVideo,
                          videoTitle: videoTitle,
                        );

                        await Future.delayed(const Duration(seconds: 3));

                        Navigator.of(stableContext, rootNavigator: true).pop();

                        if (videoUrl.isNotEmpty) {
                          
                          
                          await showVideoSavedNotification(); // Initialiser les notifications si ce n'est pas déjà fait
                          await Future.delayed(const Duration(seconds: 2));
                          optionModal(stableContext, videoUrl, videoTitle: videoTitle);

                        } else {
                          ScaffoldMessenger.of(stableContext).showSnackBar(
                            const SnackBar(content: Text("Erreur dans la génération de la vidéo")),
                          );
                        }
                      } else {
                        // Le formulaire n'est pas valide (le titre est vide), afficher un message si besoin
                        // Le validator du TextFormField affichera déjà son message.
                        log('❌ Formulaire invalide : Le titre de la vidéo est manquant.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Veuillez entrer un titre pour la vidéo.")),
                        );
                      }
                    }
                  : null, // Le bouton est désactivé si les conditions ne sont pas remplies
              child: Text(
                'Créer L\' Aperçu',
                style: TextStyle(fontSize: 16, color: isCreatePreviewButtonEnabled ? Colors.white : Colors.grey[400]),
              ),
            ),
          )
        ],
      ),
    );
  }
}