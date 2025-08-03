// Fichier : my_drawer.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:developer'; // Pour les logs
// Import pour SchedulerBinding

// Tes imports locaux
import 'package:caroussel/notif.dart';
import 'package:caroussel/option_modal.dart';
import 'package:caroussel/media_uploader.dart';
import 'package:caroussel/test_api.dart';

// Tes Providers
import 'carousel_provider.dart';
import 'drawer_settings_provider.dart';

// Pour la lecture audio
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart'; // Pour firstWhereOrNull

class MyDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const MyDrawer({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  // --- VARIABLES D'ÉTAT LOCALES QUI RESTENT DANS LE WIDGET ---
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final player = AudioPlayer();

  bool _isTitleValid = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  final List<String> _suggestedKeywords = [
    'Ambiance',
    'Nature',
    'Effet',
  ];

  @override
  void initState() {
    super.initState();
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();

    // Initialise les contrôleurs de texte avec les valeurs du provider
    _searchController.text = drawerSettingsProvider.searchKeyword;
    _titleController.text = drawerSettingsProvider.videoTitle;

    // Diffère la récupération API et la validation du titre après le premier frame.
    // Cela assure que le widget est monté et que les préférences sont chargées.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) { // S'assurer que le widget est toujours monté
        // Charger les préférences (si ce n'est pas déjà fait au démarrage de l'app)
       // await drawerSettingsProvider.loadPreferences();

        // Effectuer la recherche API initiale en utilisant le mot-clé des préférences
        _performApiSearch(drawerSettingsProvider.searchKeyword);
        _validateTitleOnChanged(); // Valider le titre après le chargement des préférences
      }
    });

    // Écoute les changements d'état du lecteur audio
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Ajoute un écouteur pour valider le titre en temps réel
    _titleController.addListener(_validateTitleOnChanged);
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Libère les ressources du lecteur audio

    // Supprime l'écouteur AVANT de disposer le contrôleur
    _titleController.removeListener(_validateTitleOnChanged);

    // Dispose des contrôleurs de texte
    _searchController.dispose();
    _titleController.dispose();

    super.dispose();
  }

  // --- FONCTIONS DE GESTION DES ACTIONS ---

  void _validateTitleOnChanged() {
    // Met à jour l'état de validité du titre
    setState(() {
      _isTitleValid = _titleController.text.trim().isNotEmpty;
    });
  }

  void _performApiSearch(String keyword) async {
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    _stopAudio(); // Arrête tout audio en cours

    // IMPORTANT : Ne PAS réinitialiser selectedMusic ici.
    // Cela écraserait la valeur potentiellement chargée des préférences.
    // drawerSettingsProvider.setSelectedMusic(null); // <-- Ligne supprimée ou commentée

    drawerSettingsProvider.setIsDropdownDisabled(false);
    drawerSettingsProvider.setIsFilePickerDisabled(false);

    // Définir le mot-clé de recherche dans le provider
    drawerSettingsProvider.setSearchKeyword(keyword.trim().isEmpty ? 'background' : keyword.trim());

    try {
      // Récupérer les données de l'API
      var fetchedData = await fetchData(keyword: drawerSettingsProvider.searchKeyword);
      drawerSettingsProvider.setApiSoundData(fetchedData); // Met à jour les données API dans le provider

      log('Données API récupérées avec succès pour le mot-clé "${drawerSettingsProvider.searchKeyword}": ${fetchedData.length} éléments');

      // Après avoir récupéré et mis à jour les données API,
      // vérifier si la musique précédemment sélectionnée (via les préférences)
      // est toujours valide dans la nouvelle liste de données.
      if (drawerSettingsProvider.selectedMusic != null &&
          !fetchedData.any((item) => item['name'] == drawerSettingsProvider.selectedMusic)) {
        // Si le son sélectionné n'est plus dans les nouvelles données, le réinitialiser.
        drawerSettingsProvider.setSelectedMusic(null);
        log('Ancien son sélectionné "${drawerSettingsProvider.selectedMusic}" n\'est plus disponible dans les nouvelles données API. Réinitialisé.');
      } else if (drawerSettingsProvider.selectedMusic != null) {
        // Si le son est toujours valide, désactiver le sélecteur de fichier local
        // pour indiquer que le son API est actif.
        drawerSettingsProvider.setIsFilePickerDisabled(true); // Désactive le sélecteur de fichier
        drawerSettingsProvider.setIsDropdownDisabled(false); // Laisser le dropdown actif
        log('Ancien son sélectionné "${drawerSettingsProvider.selectedMusic}" est toujours disponible.');
      }

    } catch (e) {
      log('Erreur lors de la récupération des données API pour le mot-clé "${drawerSettingsProvider.searchKeyword}": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la récupération des sons pour '${drawerSettingsProvider.searchKeyword}'.")),
        );
      }
    }
  }

  void _pickAudioFile() async {
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    if (drawerSettingsProvider.isFilePickerDisabled) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
      allowMultiple: false,
    );

    if (result != null) {
      drawerSettingsProvider.setAudioFilePath(result.files.single.path);
      drawerSettingsProvider.setAudioFileName(result.files.single.name);
      drawerSettingsProvider.setSelectedMusic(null); // Annule la sélection API
      drawerSettingsProvider.setIsDropdownDisabled(true); // Désactive le sélecteur API
      drawerSettingsProvider.setIsFilePickerDisabled(false); // Reste activé pour le sélecteur local
      _stopAudio();
      log("Fichier local sélectionné : ${drawerSettingsProvider.audioFilePath}");
    }
  }

  Future<void> _playAudio() async {
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() { _isPlaying = false; });
      }
      return;
    }

    if (drawerSettingsProvider.audioFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(drawerSettingsProvider.audioFilePath!));
      log('Lecture audio locale depuis : ${drawerSettingsProvider.audioFilePath}');
    } else if (drawerSettingsProvider.selectedMusic != null) {
      final Map<String, dynamic>? selectedItem = drawerSettingsProvider.apiSoundData.firstWhereOrNull(
        (item) => item['name'] == drawerSettingsProvider.selectedMusic,
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
        log('Aucun élément correspondant trouvé pour la musique sélectionnée: ${drawerSettingsProvider.selectedMusic}');
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
    if (mounted) {
      setState(() { _isPlaying = true; });
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resetAudioChoices() {
    _stopAudio();
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    drawerSettingsProvider.resetAllDrawerOptions();
    // Met à jour les contrôleurs de texte avec les valeurs réinitialisées du provider
    _searchController.text = drawerSettingsProvider.searchKeyword;
    _titleController.text = drawerSettingsProvider.videoTitle;
    _validateTitleOnChanged(); // Re-valide le titre
    _performApiSearch(drawerSettingsProvider.searchKeyword); // Recharge les sons API
  }

  // --- WIDGETS DE CONSTRUCTION D'UI ---

  Widget _buildAudioControlsSection() {
    final drawerSettingsProvider = context.watch<DrawerSettingsProvider>();
    String displayText;
    bool isAudioSelected = (drawerSettingsProvider.audioFileName != null || drawerSettingsProvider.selectedMusic != null);

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
                    drawerSettingsProvider.audioFileName ?? drawerSettingsProvider.selectedMusic!,
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
    final carouselProvider = context.watch<CarouselProvider>();
    final drawerSettingsProvider = context.watch<DrawerSettingsProvider>();

    List<String> selectedImages = carouselProvider.images;

    String selectedAudioSummaryText;
    bool isAudioSelectedForSummary = (drawerSettingsProvider.audioFileName != null || drawerSettingsProvider.selectedMusic != null);

    if (drawerSettingsProvider.audioFileName != null && drawerSettingsProvider.audioFilePath != null) {
      selectedAudioSummaryText = drawerSettingsProvider.audioFileName!;
    } else if (drawerSettingsProvider.selectedMusic != null) {
      selectedAudioSummaryText = drawerSettingsProvider.selectedMusic!;
    } else {
      selectedAudioSummaryText = 'Aucun son sélectionné';
    }

    // Déterminer si le son sélectionné du provider est réellement dans la liste `apiSoundData` actuelle.
    // Si ce n'est pas le cas, définir explicitement la valeur du sélecteur à null pour éviter les erreurs.
    String? dropdownValue = drawerSettingsProvider.selectedMusic;
    if (dropdownValue != null &&
        !drawerSettingsProvider.apiSoundData.any((item) => item['name'] == dropdownValue)) {
      dropdownValue = null;
    }

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
            initiallyExpanded: drawerSettingsProvider.isAudioOptionsExpanded,
            onExpansionChanged: (bool expanded) {
              drawerSettingsProvider.setIsAudioOptionsExpanded(expanded);
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
                      color: drawerSettingsProvider.isFilePickerDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                  enabled: !drawerSettingsProvider.isFilePickerDisabled,
                  onTap: drawerSettingsProvider.isFilePickerDisabled ? null : _pickAudioFile,
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
                            _performApiSearch(keyword);
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
                  // Utilise la valeur 'dropdownValue' vérifiée pour la cohérence
                  value: dropdownValue,
                  dropdownColor: Colors.white,
                  hint: const Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Choisissez un son proposé ',
                        style: TextStyle(color: Colors.black,fontSize:13.7),
                      ),
                    ],
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Choisissez un son proposé (via Internet)',
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromRGBO(13, 71, 161, 1))),
                  ),
                  items: drawerSettingsProvider.apiSoundData.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item['name'],
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: drawerSettingsProvider.isDropdownDisabled
                      ? null
                      : (String? value) { // Assure que la valeur est `String?`
                          drawerSettingsProvider.setSelectedMusic(value);
                          drawerSettingsProvider.setAudioFileName(null);
                          drawerSettingsProvider.setAudioFilePath(null);
                          drawerSettingsProvider.setIsFilePickerDisabled(true); // Désactive le sélecteur de fichier
                          drawerSettingsProvider.setIsDropdownDisabled(false); // Garde le dropdown activé
                          _stopAudio();
                          log("Musique sélectionnée depuis l'API: ${drawerSettingsProvider.selectedMusic}");
                        }, // The returned type 'Text' isn't returnable from a 'List<Widget>' function, as required by the closure's context.
                  selectedItemBuilder: (BuildContext context) {
                    return drawerSettingsProvider.apiSoundData.map<Widget>((item) {
                      if (dropdownValue == null) {
                        return const Text(''); // Ou ton texte d'indication si préféré
                      }
                      final selectedItem = drawerSettingsProvider.apiSoundData.firstWhereOrNull(
                            (item) => item['name'] == dropdownValue,
                      );
                      String text = selectedItem != null
                          ? (selectedItem['name'].length > 20
                          ? '${selectedItem['name'].substring(0, 20)}...'
                          : selectedItem['name'])
                          : ''; // Repli si l'élément sélectionné n'est pas trouvé
                      return Text(text, overflow: TextOverflow.ellipsis);
                    }).toList();
                  },
                ),
              ),

              _buildAudioControlsSection(),

             
              const SizedBox(height: 10),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la vidéo',
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
                            drawerSettingsProvider.setVideoTitle('');
                            _validateTitleOnChanged();
                          },
                        )
                      : null,
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre de la vidéo est obligatoire.';
                  }
                  return null;
                },
                onChanged: (value) {
                  drawerSettingsProvider.setVideoTitle(value);
                  _validateTitleOnChanged();
                },
              ),
            ),
          ),
          const Divider(),

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
                  'Titre sélectionné : ${drawerSettingsProvider.videoTitle.isNotEmpty ? drawerSettingsProvider.videoTitle : 'Non défini'}',
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
          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCreatePreviewButtonEnabled ? Colors.cyan[700] : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: isCreatePreviewButtonEnabled
                  ? () async {
                      if (_formKey.currentState!.validate()) {
                        await player.play(AssetSource('sounds/correct.mp3'));
                        // Capturer le contexte de manière stable avant les opérations asynchrones
                        final stableContext = Navigator.of(context, rootNavigator: true).context;

                        widget.scaffoldKey.currentState?.closeEndDrawer(); // Ferme le tiroir

                        // Affiche un indicateur de chargement
                        showDialog(
                          context: stableContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        String? audioSourceForVideo;

                        // Détermine la source audio pour la vidéo
                        if (drawerSettingsProvider.audioFilePath != null) {
                          audioSourceForVideo = drawerSettingsProvider.audioFilePath;
                          log('Source audio: Fichier local sélectionné: $audioSourceForVideo');
                        } else if (drawerSettingsProvider.selectedMusic != null) {
                          final Map<String, dynamic>? selectedItem = drawerSettingsProvider.apiSoundData.firstWhereOrNull(
                            (item) => item['name'] == drawerSettingsProvider.selectedMusic,
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

                        final String videoTitle = drawerSettingsProvider.videoTitle;
                        log('Titre de la vidéo : $videoTitle');

                        // Génère la vidéo
                        String videoUrl = await convertImagesToVideo(
                          selectedImages,
                          audioSource: audioSourceForVideo,
                          videoTitle: videoTitle,
                        );

                        await Future.delayed(const Duration(seconds: 3)); // Délai pour la démo

                        Navigator.of(stableContext, rootNavigator: true).pop(); // Ferme l'indicateur de chargement

                        // Gère le résultat de la génération vidéo
                        if (videoUrl.isNotEmpty) {
                          await showVideoSavedNotification();
                          await Future.delayed(const Duration(seconds: 2));
                          optionModal(stableContext, videoUrl, videoTitle: videoTitle);
                        } else {
                          ScaffoldMessenger.of(stableContext).showSnackBar(
                            const SnackBar(content: Text("Erreur dans la génération de la vidéo")),
                          );
                        }
                      } else {
                        log('❌ Formulaire invalide : Le titre de la vidéo est manquant.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Veuillez entrer un titre pour la vidéo.")),
                        );
                      }
                    }
                  : null,
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