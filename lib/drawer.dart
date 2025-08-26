import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:developer'; // Pour les logs

// Tes imports locaux
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
  const MyDrawer({super.key, required this.scaffoldKey});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  // --- VARIABLES D'ÉTAT LOCALES ---
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isTitleValid = false;

  final List<String> _suggestedKeywords = ['Ambiance', 'Nature', 'Effet'];

  @override
  void initState() {
    super.initState();
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();

    _searchController.text = drawerSettingsProvider.searchKeyword;
    _titleController.text = drawerSettingsProvider.videoTitle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performApiSearch(drawerSettingsProvider.searchKeyword);
        _validateTitleOnChanged();
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _titleController.addListener(_validateTitleOnChanged);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.removeListener(_validateTitleOnChanged);
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // --- GESTION DES ACTIONS ---

  void _validateTitleOnChanged() {
    setState(() {
      _isTitleValid = _titleController.text.trim().isNotEmpty;
    });
  }

  void _performApiSearch(String keyword) async {
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    _stopAudio();

    drawerSettingsProvider.setIsDropdownDisabled(false);
    drawerSettingsProvider.setIsFilePickerDisabled(false);
    drawerSettingsProvider.setSearchKeyword(keyword.trim().isEmpty ? 'holiday' : keyword.trim());

    try {
      var fetchedData = await fetchData(keyword: drawerSettingsProvider.searchKeyword);
      drawerSettingsProvider.setApiSoundData(fetchedData);
      log('Données API récupérées pour "${drawerSettingsProvider.searchKeyword}": ${fetchedData.length} éléments');

      if (drawerSettingsProvider.selectedMusic != null && !fetchedData.any((item) => item['name'] == drawerSettingsProvider.selectedMusic)) {
        drawerSettingsProvider.setSelectedMusic(null);
        log('Ancien son "${drawerSettingsProvider.selectedMusic}" non disponible. Réinitialisé.');
      } else if (drawerSettingsProvider.selectedMusic != null) {
        drawerSettingsProvider.setIsFilePickerDisabled(true);
        drawerSettingsProvider.setIsDropdownDisabled(false);
        log('Ancien son "${drawerSettingsProvider.selectedMusic}" toujours disponible.');
      }
    } catch (e) {
      log('Erreur API pour "${drawerSettingsProvider.searchKeyword}": $e');
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
      drawerSettingsProvider.setSelectedMusic(null);
      drawerSettingsProvider.setIsDropdownDisabled(true);
      drawerSettingsProvider.setIsFilePickerDisabled(false);
      _stopAudio();
      log("Fichier local sélectionné : ${drawerSettingsProvider.audioFilePath}");
    }
  }

  Future<void> _playAudio() async {
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }

    String? audioSource;
    if (drawerSettingsProvider.audioFilePath != null) {
      audioSource = drawerSettingsProvider.audioFilePath!;
      await _audioPlayer.play(DeviceFileSource(audioSource));
      log('Lecture locale : $audioSource');
    } else if (drawerSettingsProvider.selectedMusic != null) {
      final selectedItem = drawerSettingsProvider.apiSoundData.firstWhereOrNull(
        (item) => item['name'] == drawerSettingsProvider.selectedMusic,
      );

      if (selectedItem != null) {
        final soundUrl = await getSoundDownloadUrl(selectedItem['id']);
        if (soundUrl != null) {
          await _audioPlayer.play(UrlSource(soundUrl));
          log('Lecture API : $soundUrl');
        } else {
          log('URL API non obtenue pour ID: ${selectedItem['id']}');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible de lire le son de l'API")));
        }
      } else {
        log('Musique sélectionnée non trouvée: ${drawerSettingsProvider.selectedMusic}');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le son sélectionné n'est plus disponible")));
      }
    } else {
      log('Aucune source audio sélectionnée.');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner un son")));
    }

    if (audioSource != null || (drawerSettingsProvider.selectedMusic != null && await getSoundDownloadUrl(drawerSettingsProvider.apiSoundData.firstWhereOrNull((item) => item['name'] == drawerSettingsProvider.selectedMusic)?['id'] ?? 0) != null)) {
      setState(() => _isPlaying = true);
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  void _resetAudioChoices() {
    _stopAudio();
    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    drawerSettingsProvider.resetAllDrawerOptions();
    _searchController.text = drawerSettingsProvider.searchKeyword;
    _titleController.text = drawerSettingsProvider.videoTitle;
    _validateTitleOnChanged();
    _performApiSearch(drawerSettingsProvider.searchKeyword);
  }

  Future<void> _createPreview() async {
    if (!_formKey.currentState!.validate()) {
      log('❌ Formulaire invalide : Le titre est manquant.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez entrer un titre pour la vidéo.")));
      return;
    }

    await AudioPlayer().play(AssetSource('sounds/correct.mp3'));
    final stableContext = Navigator.of(context, rootNavigator: true).context;
    widget.scaffoldKey.currentState?.closeEndDrawer();

    showDialog(
      context: stableContext,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    final drawerSettingsProvider = context.read<DrawerSettingsProvider>();
    final carouselProvider = context.read<CarouselProvider>();
    String? audioSourceForVideo;

    if (drawerSettingsProvider.audioFilePath != null) {
      audioSourceForVideo = drawerSettingsProvider.audioFilePath;
    } else if (drawerSettingsProvider.selectedMusic != null) {
      final selectedItem = drawerSettingsProvider.apiSoundData.firstWhereOrNull((item) => item['name'] == drawerSettingsProvider.selectedMusic);
      if (selectedItem != null) {
        audioSourceForVideo = await getSoundDownloadUrl(selectedItem['id']);
      } else {
        log('Son API non disponible pour la vidéo.');
        if(mounted) ScaffoldMessenger.of(stableContext).showSnackBar(const SnackBar(content: Text("Le son API sélectionné n'est plus disponible.")));
        Navigator.of(stableContext, rootNavigator: true).pop();
        return;
      }
    }

    final String videoTitle = drawerSettingsProvider.videoTitle;
    log('Génération vidéo avec titre "$videoTitle" et audio: $audioSourceForVideo');

    String videoUrl = await convertImagesToVideo(
      carouselProvider.images,
      audioSource: audioSourceForVideo,
      videoTitle: videoTitle,
    );

    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(stableContext, rootNavigator: true).pop();

    if (videoUrl.isNotEmpty) {
      log('✅ Vidéo générée : $videoUrl');
      //await showVideoSavedNotification();
      //await Future.delayed(const Duration(seconds: 7));
      optionModal(stableContext, videoUrl, videoTitle: videoTitle);
    } else {
      ScaffoldMessenger.of(stableContext).showSnackBar(const SnackBar(content: Text("Erreur dans la génération de la vidéo")));
    }
  }

  // --- WIDGETS DE CONSTRUCTION D'UI ---

  Widget _buildHeader() {
    return SizedBox(
      height: 175,
      child: DrawerHeader(
        decoration: BoxDecoration(color: Colors.cyan[700]),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paramètres', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text.rich(TextSpan(text: 'Personnalisez votre expérience \net ajustez vos préférences ici.', style: TextStyle(color: Colors.white70, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioOptions(DrawerSettingsProvider provider) {
    return ExpansionTile(
      key: const PageStorageKey('audioOptions'),
      initiallyExpanded: provider.isAudioOptionsExpanded,
      onExpansionChanged: (expanded) => provider.setIsAudioOptionsExpanded(expanded),
      title: const Text('Options Audio'),
      leading: const Padding(padding: EdgeInsets.only(left: 16.0), child: Icon(Icons.volume_up)),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      children: <Widget>[
        _buildWarningBox(),
        _buildAudioFilePicker(provider),
        const Divider(),
        _buildApiSoundSection(provider),
        _buildAudioControlsSection(provider),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildWarningBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Les fichiers audio importés doivent être libres de droits. L'application ne vérifie pas la licence des fichiers locaux.",
                style: TextStyle(fontSize: 13, color: Colors.orange[800], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioFilePicker(DrawerSettingsProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
      child: ListTile(
        leading: const Icon(Icons.folder_open),
        title: Text("Parcourir un fichier audio", style: TextStyle(color: provider.isFilePickerDisabled ? Colors.grey : Colors.black)),
        enabled: !provider.isFilePickerDisabled,
        onTap: provider.isFilePickerDisabled ? null : _pickAudioFile,
      ),
    );
  }

  Widget _buildApiSoundSection(DrawerSettingsProvider provider) {
    String? dropdownValue = provider.selectedMusic;
    if (!provider.apiSoundData.any((item) => item['name'] == dropdownValue)) {
      dropdownValue = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sons de l\'API :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4.0,
                runSpacing: 1.0,
                children: _suggestedKeywords.map((keyword) {
                  return ActionChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12)),
                    labelStyle: TextStyle(color: Colors.blue[800]),
                    backgroundColor: Colors.blue[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blue.shade200)),
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
            value: dropdownValue,
            hint: const Row(children: [Icon(Icons.music_note, color: Colors.blue), SizedBox(width: 8), Text('Choisissez un son proposé', style: TextStyle(color: Colors.black, fontSize: 13.7))]),
            decoration: const InputDecoration(labelText: 'Choisissez un son proposé (via Internet)', border: OutlineInputBorder()),
            items: provider.apiSoundData.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item['name'],
                child: Text(item['name']),
                onTap: () => provider.setSelectedMusicAuthor(item['username']),
              );
            }).toList(),
            onChanged: provider.isDropdownDisabled ? null : (String? value) {
              provider.setSelectedMusic(value);
              provider.setAudioFileName(null);
              provider.setAudioFilePath(null);
              provider.setIsFilePickerDisabled(true);
              provider.setIsDropdownDisabled(false);
              _stopAudio();
              log("Musique API sélectionnée: ${provider.selectedMusic}");
            },
            selectedItemBuilder: (BuildContext context) {
              return provider.apiSoundData.map<Widget>((item) {
                final selectedItem = provider.apiSoundData.firstWhereOrNull((i) => i['name'] == dropdownValue);
                String text = selectedItem != null ? (selectedItem['name'].length > 20 ? '${selectedItem['name'].substring(0, 20)}...' : selectedItem['name']) : '';
                return Text(text, overflow: TextOverflow.ellipsis);
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioControlsSection(DrawerSettingsProvider provider) {
    bool isAudioSelected = provider.audioFileName != null || provider.selectedMusic != null;
    String displayText = isAudioSelected ? "Son : ${provider.audioFileName ?? provider.selectedMusic!}" : "Aucun son sélectionné";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_down_rounded, color: isAudioSelected ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(displayText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isAudioSelected ? Colors.black : Colors.grey), overflow: TextOverflow.ellipsis)),
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
            style: ElevatedButton.styleFrom(backgroundColor: isAudioSelected ? Colors.blue[600] : Colors.grey[300], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            onPressed: isAudioSelected ? _stopAudio : null,
            style: ElevatedButton.styleFrom(backgroundColor: isAudioSelected ? Colors.red[600] : Colors.grey[300], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput(DrawerSettingsProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre de la vidéo',
            hintText: 'Ex: "Mes vacances d\'été"',
            prefixIcon: const Icon(Icons.edit),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _titleController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _titleController.clear();
                      provider.setVideoTitle('');
                      _validateTitleOnChanged();
                    },
                  )
                : null,
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Le titre est obligatoire.' : null,
          onChanged: (value) {
            provider.setVideoTitle(value);
            _validateTitleOnChanged();
          },
        ),
      ),
    );
  }

  Widget _buildSummary(DrawerSettingsProvider provider) {
    bool isAudioSelected = provider.audioFileName != null || provider.selectedMusic != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Récapitulatif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan[800])),
          const SizedBox(height: 8),
          Text('🎬 Titre : ${provider.videoTitle.isNotEmpty ? provider.videoTitle : 'Non défini'}', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          Text('🎵 Son : ${provider.audioFileName ?? provider.selectedMusic ?? 'Aucun'}', style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('👤 Auteur : ${provider.selectedMusicAuthor ?? 'Fichier personnel'}', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 10),
          _buildPlayStopButtons(isAudioSelected),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCreatePreviewButtonEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _resetAudioChoices,
            icon: const Icon(Icons.restart_alt),
            label: const Text("J’annule mon choix"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[800],
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
         
          Padding(
            padding: const EdgeInsets.only(top:10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCreatePreviewButtonEnabled ? Colors.cyan[700] : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: isCreatePreviewButtonEnabled ? _createPreview : null,
              child: Text(
                'Créer L\'Aperçu',
                style: TextStyle(
                  fontSize: 16,
                  color: isCreatePreviewButtonEnabled ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan)),
            SizedBox(height: 16),
            Text('Création en cours...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, decoration: TextDecoration.none, fontFamily: 'RobotoMono')),
            SizedBox(height: 8),
            Text('Veuillez patienter...', style: TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.none, fontFamily: 'RobotoMono')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carouselProvider = context.watch<CarouselProvider>();
    final drawerSettingsProvider = context.watch<DrawerSettingsProvider>();
    bool isCreatePreviewButtonEnabled = carouselProvider.images.length >= 2 && _isTitleValid;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(),
          _buildAudioOptions(drawerSettingsProvider),
          const Divider(),
          _buildTitleInput(drawerSettingsProvider),
          const Divider(),
          _buildSummary(drawerSettingsProvider),
          _buildActionButtons(isCreatePreviewButtonEnabled),
        ],
      ),
    );
  }
}
