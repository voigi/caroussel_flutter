// lib/drawer_settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pour la persistance des données

class DrawerSettingsProvider with ChangeNotifier {
  // --- Variables d'état pour les options du tiroir ---
  String? _audioFileName;
  String? _audioFilePath; // Chemin local du fichier audio
  String? _selectedMusic; // Nom de la musique sélectionnée via l'API
  String? _selectedMusicAuthor; // Auteur de la musique sélectionnée
  bool _isDropdownDisabled = false;
  bool _isFilePickerDisabled = false;
  List _apiSoundData = []; // Données des sons de l'API
  String _searchKeyword = 'holiday'; // Mot-clé de recherche par défaut
  String _videoTitle = ''; // Titre de la vidéo
  bool _isAudioOptionsExpanded = false; // État d'expansion de la tuile audio

  // --- Getters ---
  String? get audioFileName => _audioFileName;
  String? get audioFilePath => _audioFilePath;
  String? get selectedMusic => _selectedMusic;
  String? get selectedMusicAuthor => _selectedMusicAuthor;
  bool get isDropdownDisabled => _isDropdownDisabled;
  bool get isFilePickerDisabled => _isFilePickerDisabled;
  List get apiSoundData => _apiSoundData;
  String get searchKeyword => _searchKeyword;
  String get videoTitle => _videoTitle;
  bool get isAudioOptionsExpanded => _isAudioOptionsExpanded;

  // --- Setters (qui notifient les auditeurs) ---
  void setAudioFileName(String? name) {
    _audioFileName = name;
    notifyListeners();
    _savePreferences(); // Sauvegarde immédiatement
  }

  void setAudioFilePath(String? path) {
    _audioFilePath = path;
    notifyListeners();
    _savePreferences();
  }

  void setSelectedMusic(String? music) {
    _selectedMusic = music;
    notifyListeners();
    _savePreferences();
  }

  void setIsDropdownDisabled(bool value) {
    _isDropdownDisabled = value;
    notifyListeners();
    _savePreferences();
  }

  void setIsFilePickerDisabled(bool value) {
    _isFilePickerDisabled = value;
    notifyListeners();
    _savePreferences();
  }

  void setApiSoundData(List data) {
    _apiSoundData = data;
    notifyListeners();
    // Pas besoin de sauvegarder les données API dans les préférences partagées,
    // car elles sont récupérées à chaque fois (ou stockées différemment si nécessaire).
  }

  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
    _savePreferences();
  }

  void setVideoTitle(String title) {
    _videoTitle = title;
    notifyListeners();
    _savePreferences();
  }

  void setIsAudioOptionsExpanded(bool expanded) {
    _isAudioOptionsExpanded = expanded;
    notifyListeners();
    _savePreferences();
  }

void setSelectedMusicAuthor(String? author) {
    _selectedMusicAuthor = author;
    notifyListeners();
    _savePreferences();
  }


  // --- Méthodes pour la persistance avec shared_preferences ---
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('audioFileName', _audioFileName ?? '');
    prefs.setString('audioFilePath', _audioFilePath ?? '');
    prefs.setString('selectedMusic', _selectedMusic ?? '');
    prefs.setString('selectedMusicAuthor', _selectedMusicAuthor ?? '');
    prefs.setBool('isDropdownDisabled', _isDropdownDisabled);
    prefs.setBool('isFilePickerDisabled', _isFilePickerDisabled);
    prefs.setString('searchKeyword', _searchKeyword);
    prefs.setString('videoTitle', _videoTitle);
    prefs.setBool('isAudioOptionsExpanded', _isAudioOptionsExpanded);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _audioFileName = prefs.getString('audioFileName');
    _audioFilePath = prefs.getString('audioFilePath');
    _selectedMusic = prefs.getString('selectedMusic');
    _selectedMusicAuthor = prefs.getString('selectedMusicAuthor');
    _isDropdownDisabled = prefs.getBool('isDropdownDisabled') ?? false;
    _isFilePickerDisabled = prefs.getBool('isFilePickerDisabled') ?? false;
    _searchKeyword = prefs.getString('searchKeyword') ?? 'background';
    _videoTitle = prefs.getString('videoTitle') ?? '';
    _isAudioOptionsExpanded = prefs.getBool('isAudioOptionsExpanded') ?? false;
    notifyListeners(); // Informe les widgets de l'état chargé
  }

  // Méthode de réinitialisation complète des options du tiroir
  void resetAllDrawerOptions() {
    _audioFileName = null;
    _audioFilePath = null;
    _selectedMusic = null;
    _isDropdownDisabled = false;
    _isFilePickerDisabled = false;
    _searchKeyword = 'holiday';
    _videoTitle = '';
    _selectedMusicAuthor = null;
    // _apiSoundData n'est généralement pas réinitialisée ici car elle vient de l'API
    _isAudioOptionsExpanded = false;
    notifyListeners();
    _savePreferences(); // Sauvegarde l'état réinitialisé
  }
}