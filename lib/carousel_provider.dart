import 'package:flutter/material.dart';
import 'dart:developer';



class CarouselProvider with ChangeNotifier {
  List<String> _images;
  int? _autoScrollValue;
    List<String> _selectedImages = [];

  List<String> get selectedImages => _selectedImages;

  CarouselProvider({List<String>? images, int? autoScrollValue})
      : _images = images ?? [], // Utilisation d'une liste vide si aucune donnée n'est passée
        _autoScrollValue = autoScrollValue ?? 0; // Valeur par défaut de 0 pour le défilement

  List<String> get images => _images;
  int? get autoScrollValue => _autoScrollValue;

  // Méthode pour mettre à jour une image à un index spécifique
  void updateImageAtIndex(int index, String newPath) {
    if (index >= 0 && index < _images.length) {
      _images[index] = newPath;
      log("Image mise à jour à l'index $index avec le chemin : $newPath");
      notifyListeners();
    } else {
      log("Index invalide : $index");
    }
  }

  // Méthode pour ajouter une image à la liste
  void addImage(String path) {
    _images.add(path);
    notifyListeners();
  }

  // Méthode pour supprimer une image à un index donné
  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  void updateAutoScrollValue(int? value) {
    _autoScrollValue = value;
    notifyListeners();
  }

  void setSelectedImages(List<String> images) {
    _selectedImages = images;
    notifyListeners();  // Notifie les auditeurs que l'état a changé
  }
}
